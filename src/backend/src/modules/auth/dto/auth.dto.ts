import { IsEmail, IsString, Length, MinLength } from 'class-validator';

export class RegisterUserDto {
  @IsEmail()
  login_identifier!: string;

  @IsString()
  @MinLength(12)
  @Length(1, 128)
  password!: string;
}

export class LoginDto {
  @IsEmail()
  login_identifier!: string;

  @IsString()
  @MinLength(1)
  @Length(1, 128)
  password!: string;
}
