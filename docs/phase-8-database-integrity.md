# Phase 8 - Database Integrity and Multi-Facility Foundation

Scope: resolve only the three database architecture limitations recorded by the
Phase 7.1 audit. No new clinical domain was started.

## The three reported issues and what they actually were

### 1. `clinical_visits.staf_id` had no foreign key

**Reported:** the column exists but is not backed by a reference.

**Actual root cause:** migration `1710000000000` declared `staf_id uuid` as a
bare column with no `REFERENCES` clause. The TypeORM entity
`ClinicalVisitRecord` already modelled the relation correctly with
`@ManyToOne(() => StaffRecord, { nullable: true, onDelete: 'RESTRICT' })`, so the
ORM and the database disagreed: the schema permitted a visit to name a clinician
who never existed, while the entity implied otherwise.

The column is `staf_id` (not `staff_id`) and targets `staff_profiles.staff_id`,
which is the primary key of that table.

### 2. `tenant_id` had no referential integrity

**Reported:** `tenant_id` is used by authorization and data structures but has no
adequate referential integrity.

**Actual root cause - there is no Tenant entity.** The project has ten entities
and none of them is a tenant:

```
clinical-visit, facility-membership, facility, medication, patient,
prescription-item, prescription, staff, sync-operation, user
```

Only three tables carry a `tenant_id` column at all:

| table           | tenant_id | how it is produced                        |
| --------------- | --------- | ----------------------------------------- |
| `facilities`    | NOT NULL  | authoritative anchor for tenant identity   |
| `clinical_visits` | NOT NULL | denormalized copy, server derived         |
| `prescriptions`   | NOT NULL | denormalized copy, server derived         |

`facility_memberships`, `patients` and `sync_operations` have **no** `tenant_id`
column at all. A caller's tenant identity is derived by joining the membership's
facility (`AuthService` reads `membership.facility.tenant_id`), and the JWT
carries only `sub` and `login_identifier`.

`tenant_id` is a free text `varchar(100)`. There is no `tenants` table, so there
is nothing for `facilities.tenant_id` to reference. Introducing one would be a
new domain, which is out of scope, and pointing the column at an invented table
would be fake referential integrity.

**Decision:** no `tenants` table was created. Instead the *pair* is constrained,
which is what actually mattered. See "Pair integrity" below.

### 3. `facilities.tenant_id` was UNIQUE

**Reported:** one tenant can own only one facility.

**Actual root cause:** migration `1710000002000` created
`tenant_id varchar(100) NOT NULL UNIQUE` on `facilities`. That single constraint
capped every tenant at exactly one clinic.

Multi-facility was already compatible with the rest of the architecture:

- `AuthService` returns a **list** of memberships, each carrying its own
  `(facility_id, tenant_id)` pair, so a user can hold several.
- `facility_memberships` is keyed `UNIQUE (user_id, facility_id)`, which already
  permits a user to belong to many facilities.
- No service, repository or query anywhere assumed that `tenant_id` resolves to a
  single facility.

So the constraint was the only obstacle.

## Migration

One new migration, `1710000006000-HardenDatabaseIntegrity`. No already applied
migration was edited.

### Goal A - staff foreign key

```sql
ALTER TABLE clinical_visits
ADD CONSTRAINT fk_clinical_visits_staf
FOREIGN KEY (staf_id) REFERENCES staff_profiles (staff_id)
ON DELETE RESTRICT;
```

`RESTRICT` was chosen over `CASCADE` deliberately: deleting a clinician must
never erase clinical history. With the constraint in place, removing a staff
profile that still has visits is rejected and both rows survive.

The column stays nullable. A visit recorded without a clinician is a legitimate
state, and NULL passes a foreign key check.

Before applying, existing data was inspected for orphans:

| check                                             | result |
| ------------------------------------------------- | ------ |
| clinical visits with `staf_id`                     | 1      |
| of those, not present in `staff_profiles`          | **0**  |
| prescriptions with no matching `prescribed_by_staff_id` | **0** |

No orphan visits existed, so the migration applied without a data fix, a backfill
or any record being deleted.

### Goal C - multi-facility support

```sql
ALTER TABLE facilities DROP CONSTRAINT facilities_tenant_id_key;
CREATE INDEX idx_facilities_tenant_id ON facilities (tenant_id);
```

Uniqueness was replaced by a plain lookup index, which is what tenant-scoped
queries actually need.

### Pair integrity (the strongest available substitute for a tenant FK)

```sql
ALTER TABLE facilities
ADD CONSTRAINT uq_facilities_facility_tenant UNIQUE (facility_id, tenant_id);

ALTER TABLE clinical_visits
ADD CONSTRAINT fk_clinical_visits_facility_tenant
FOREIGN KEY (facility_id, tenant_id)
REFERENCES facilities (facility_id, tenant_id)
ON DELETE RESTRICT;

ALTER TABLE prescriptions
ADD CONSTRAINT fk_prescriptions_facility_tenant
FOREIGN KEY (facility_id, tenant_id)
REFERENCES facilities (facility_id, tenant_id)
ON DELETE RESTRICT;
```

`(facility_id, tenant_id)` is trivially unique because `facility_id` is already
the primary key, so the parent key can never fail.

This is the important part of the phase. It removes the ability of a child row
to claim a tenant that contradicts its facility, which is precisely the defect
class the Phase 7.1 authorization fix had to defend against at runtime. The
schema now prevents the bad state, and the authorization layer still refuses it.

**Legacy data is unaffected.** PostgreSQL applies MATCH SIMPLE composite foreign
keys only when *every* referencing column is non-NULL. Clinical visits that
predate facility assignment keep `facility_id IS NULL`, remain valid without a
backfill, and stay visible to their own tenant through the existing legacy branch
in `IstoriaKlinisService.visitScope`.

### Down migration

Rollback drops the three foreign keys, the pair unique constraint and the index,
then restores `UNIQUE (tenant_id)`. Because multi-facility tenants now legitimately
exist, that last step can legitimately fail. Rather than emitting an opaque
constraint violation, the down migration first checks for tenants owning more
than one facility and throws a descriptive error naming the offending tenants.

### ORM consistency

`FacilityRecord.tenant_id` lost its `unique: true` and gained the two index
decorators matching the new schema. `ClinicalVisitRecord` needed no change; its
`staf` relation already matched. `synchronize` remains `false` and migrations are
still the only source of schema truth.

## Tenant and facility model after Phase 8

```
facilities (authoritative)
   facility_id  PK
   tenant_id    free text, indexed, NOT unique   <- one tenant, many facilities

facility_memberships
   UNIQUE (user_id, facility_id)                 <- a user, many facilities
   tenant derived through the facility

clinical_visits
   (facility_id, tenant_id) -> facilities         <- pair can never disagree
   staf_id -> staff_profiles                      <- RESTRICT

prescriptions
   (facility_id, tenant_id) -> facilities         <- pair can never disagree
   prescribed_by_staff_id -> staff_profiles       <- RESTRICT (Phase 7)

patients
   facility_id -> facilities                      <- tenant derived, no copy
```

## Authorization model after Phase 8

Unchanged and deliberately so. Pair based authorization was already correct and
Phase 8 did not relax it.

- A user authorized for `Tenant X / Facility A` gains **nothing** in
  `Tenant X / Facility B`. Sharing a tenant is not a grant. Verified by test.
- The tenant wide route `GET /api/istoria-klinis/tenant/:tenantId` still filters
  by the caller's own membership pairs, so it returns only facilities the caller
  actually belongs to.
- Granting the explicit membership for the sibling facility immediately makes the
  record visible, proving the decision is driven by the pair and not the tenant.
- `facility_id` is not part of the clinical visit create contract and is stripped
  by the validation pipe, so ownership cannot be steered from a request body.

## Tests

New `src/backend/test/database-integrity.e2e-spec.ts` (9 tests, database level):

| test | asserts |
| ---- | ------- |
| one tenant owns several facilities | two facilities share a `tenant_id` |
| tenant index is present, uniqueness gone | `facilities_tenant_id_key` absent, `idx_facilities_tenant_id` present |
| valid staff reference | visit insert with a real `staff_profiles` row succeeds |
| nonexistent staff reference | insert rejected with `fk_clinical_visits_staf` |
| staff delete safety | delete rejected, staff row **and** visit row both survive |
| visit with contradicting tenant | rejected with `fk_clinical_visits_facility_tenant` |
| prescription with contradicting tenant | rejected with `fk_prescriptions_facility_tenant` |
| legacy visit without a facility | still accepted |
| no cascade anywhere | zero foreign keys with `CASCADE` or `SET NULL` |

Extended `src/backend/test/security.e2e-spec.ts` (3 tests, authorization level):

| test | asserts |
| ---- | ------- |
| one tenant holds two facilities, still isolated | sibling facility record denied on detail, patient history, list and tenant route; becomes visible only after an explicit membership is added |
| cross tenant sibling facility denied | tenant A caller refused tenant B's second facility on every surface |
| forged facility and tenant pair | posting a foreign patient with a foreign `tenant_id` is refused; an injected `facility_id` is rejected by validation |

### Two existing regressions had to be adapted, not deleted

Phase 7 and 7.1 both contain tests that deliberately manufacture a
`(facility, tenant)` mismatch to prove the authorization layer defends against
tampered or migrated rows. The new composite foreign key makes that row
impossible to create, so both tests now build it inside a transaction with
`SET LOCAL session_replication_role = replica`.

This was a deliberate choice. The authorization fix is defence in depth for rows
that predate the constraint, and deleting those tests would have thrown away
coverage of a real scenario. `SET LOCAL` is scoped to one transaction on one
pooled connection and is undone by `COMMIT`, so no other test can observe a
weakened constraint. Both tests still fail if the authorization fix is reverted.

The adaptation is itself evidence the constraint works: before the change these
two tests passed by inserting the bad row directly, and they failed immediately
once the constraint landed.

### Regression proof

Both new guarantees were verified to fail without the fix, on a disposable
database:

- Restoring `UNIQUE (facilities.tenant_id)` and inserting a second facility into
  the same tenant fails with
  `duplicate key value violates unique constraint "facilities_tenant_id_key"`.
- Dropping `fk_clinical_visits_staf` and inserting a visit with a random
  `staf_id` succeeds again, producing a detectable orphan visit.

The disposable database was dropped afterwards.

## Verification

| check | result |
| ----- | ------ |
| `npm run build` | pass |
| `npm run lint` | pass, no warnings |
| `npm test` | 6 suites / 55 tests pass |
| `npm run test:e2e` | 6 suites / 62 tests pass (was 50) |
| `npm run migration:show` | 7 migrations applied in order |
| foreign keys | 15 total, all `RESTRICT`, zero `CASCADE`, zero `SET NULL` |
| `facilities.tenant_id` unique | removed |
| `idx_facilities_tenant_id` | present |
| `fk_clinical_visits_staf` | present, `RESTRICT` |
| pair foreign keys | present on `clinical_visits` and `prescriptions` |
| `flutter analyze` | pass, no issues |
| `flutter test` | 41 pass, 1 skipped |
| cross-stack offline acceptance | pass, exactly one patient, visit, prescription and item after replay |

Acceptance evidence for this run:

```
patient       cd42f939-1a6e-44d9-a0d1-a37e8e6457aa
visit         0bd01547-bf1a-4a81-9edc-d807810a37fd
prescription  4ccd04a2-63d7-49e4-8ff1-f6268c8e835f
```

No Flutter file was modified by Phase 8. The schema changes are invisible to the
client models, and the offline queue, dependency ordering and `operation_id`
idempotency were not touched.

## Known limitations

1. **No authoritative Tenant entity. This is the Phase 8 blocker.** Tenant
   identity is still free text anchored only on `facilities.tenant_id`. Nothing
   validates the format, nothing prevents a typo, and no tenant row can be
   created, renamed, suspended or audited. A real tenant FK requires a dedicated
   tenant domain design phase, which was explicitly out of scope here. The pair
   constraints mitigate the dangerous half of the problem (a child row cannot
   contradict its facility) but do not make tenant identity a first class,
   referentially sound concept.

2. **`tenant_id` can still disagree with reality in one direction.** A facility
   may be inserted with an arbitrary tenant string, and nothing detects that two
   facilities were meant to share a health system but were given different
   labels.

3. **`facility_memberships` has no `tenant_id` column.** Tenant is resolved
   through the facility, which is consistent, but it means a membership cannot
   be asserted independently of the facility it points at. Adding a tenant column
   would allow contradictory membership rows and is deliberately not done.

4. **Legacy clinical visits have no `facility_id` and therefore no pair
   constraint.** They remain governed by the authorization layer's legacy
   tenant-only branch. They are now safe from the composite key by PostgreSQL's
   MATCH SIMPLE semantics, not by design. A backfill assigning each legacy visit
   to the correct facility would let the pair constraint cover them.

5. **`staf_id` is nullable and can stay null.** The foreign key prevents a
   *wrong* clinician but not a *missing* one. Nothing currently requires a visit
   to record who performed it.

6. **Multi-facility support is a database and authorization capability only.**
   There is no facility picker in the application, and a user with memberships
   in several facilities has no way to choose an active facility. The pair based
   authorization grants access to all of them, which is correct but not yet a
   usable product behaviour.

7. **Patient records remain facility scoped with no tenant column.** This is
   consistent, and it inherits the tenant identity of the facility. A patient
   cannot be shared across two facilities of the same tenant, which may not be
   the eventual intent.

8. **Everything from Phase 7.1 that was not a database issue still applies**:
   prescription update and amendment, pharmacy workflow, stock, procurement,
   interactions, allergies, catalog seed, offline catalog caching, billing,
   insurance, reporting, biometrics, DHIS2/TLHIS, laboratory, radiology and the
   patient portal remain deferred.