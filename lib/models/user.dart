part of arista;

class User
{
    @Id() String id;
    @Field() String nombre;
    @Field() String apellido;
    @Field() String email;
    
    @ReferenceId() List<String> eventos = [];
}

class Admin
{
    @Field() bool admin;
}

class Password
{
    @Field() String password;
}

class Money
{
    @Field() num money = 0;
}

class UserAdmin extends User with Admin
{
    
}

class UserSecure extends User with Password
{
    
}

class UserMoney extends User with Money
{
    
}

class UserComplete extends User with Admin, Password, Money
{
    
}

