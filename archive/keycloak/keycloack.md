creat un realm
    Manage realms
    ceate realm 
    nom du realm (flotio)
    enable on 
    create 
si besoin selectioner le realm

client 
    Create client
    clientID flotio_front
    Name flotio_front
    Description au besoin
    Next
    Client authentication pas claire 
    Next
    root url front,( dev= [localhost:3000](http://localhost:3000))
    Home URL front,( dev= [localhost:3000](http://localhost:3000/dasboard)
    Web origins  front,( dev= [localhost:3000](http://localhost:3000)


user 
    username admin  
    email admin@flotio.dev 
    First name admin
    Last name admin


create role 
    realm roles 
    create roles 
    Role name flotio-realm-admin-role
    description : role administrateur pour le domaine flotio
    SAVE 
    associted roles 
        ajouter tout les role (realm roles et client role)

user   
    assign the roles create 
    create password (admin)

connection github 
    on keyclock set identity providers
        github
    on github
    add Oauth on your oragnisation 
    crete client id 
    create client secret 
    set url 
    