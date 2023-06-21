#Load Abe's SwapShop!
docker run -p 7000:80 -d --restart always --log-driver gelf --log-opt gelf-address=tcp://localhost:12201 blueteamninja/swagshop
docker run -p 8080:80 -d --restart always tarampampam/webhook-tester

#Ricks Sysadmin stuffs!

#Dan's Log magic goes here