#Load Abe's SwapShop!
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop

#Ricks Sysadmin stuffs!

#Dan's Log magic goes here