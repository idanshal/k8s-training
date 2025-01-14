#!/bin/bash

source ../../tools/solution_utils.sh

write-db-deploy-yaml(){
  rm -f db-deploy.yaml
  cat > db-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lc-db # The name of your deployment
  labels:
    app: lc-db  # The label of your deployment
spec:
  replicas: 1 # Number of replicated pods
  selector:
    matchLabels:
      app: lc-db # defines how the Deployment finds which Pods to manage. Should match labels defined in the Pod template
  template:
    metadata:
      labels:
        app: lc-db # The label of the pod to match selectors
    spec:
      containers:
      - name: lc-db # The container name
        image: mongo:4.4.22 # The DockerHub image
        ports:
        - containerPort: 27017 # Open pod port 80 for the container
        livenessProbe:
          exec:
            command:
            - mongo
            - --eval
            - "db.adminCommand('ping')"
          initialDelaySeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mongo
            - --eval
            - "db.adminCommand('ping')"
          initialDelaySeconds: 5
          timeoutSeconds: 1
        env: # [OPTIONAL] add environments values
        - name: MONGO_INITDB_ROOT_USERNAME
          valueFrom:
            secretKeyRef:
              name: lc-db
              key: username
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: lc-db
              key: password
        volumeMounts:
        - name: data
          mountPath: /data/db

      volumes:
      - name: data
        hostPath:
          path: /var/letschat
      nodeSelector:
        app: letschat
EOF
  cat db-deploy.yaml
}



label-node(){
  printWaitExec kubectl label node kind-worker app=letschat
  printWaitExec kubectl get no --show-labels
}

clear
echo
echo "████████╗  █████╗  ███████╗ ██╗  ██╗      █████╗      "
echo "╚══██╔══╝ ██╔══██╗ ██╔════╝ ██║ ██╔╝     ██╔══██╗ ██╗ "
echo "   ██║    ███████║ ███████╗ █████╔╝      ╚█████╔╝ ╚═╝ "
echo "   ██║    ██╔══██║ ╚════██║ ██╔═██╗           ██╗ ██╗ "
echo "   ██║    ██║  ██║ ███████║ ██║  ██╗     ╚█████╔╝ ╚═╝ "
echo "   ╚═╝    ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝      ╚════╝      "
echo

echo -e "${RED}Make sure you run this solution after you successfully executed Task 8 solution${NC}"
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "1. Add label to one of the nodes ${NC}"
echo -n ">>"
read text
label-node
read text
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "2. Add nodeSelector to the Lets-Chat-DB Deployment and volume to the hostPath ${NC}"
echo -n ">>"
read text
echo -e "${GREEN}Writing dc-deploy.yaml file:${NC}"
eachDashes
write-db-deploy-yaml
eachDashes
next
echo -e "${GREEN}Update the db Deployment:${NC}"
apply-change db-deploy.yaml
read text
clear
echo -ne "${GREEN}Verify the pods are ready, ${NC}"
get-pods-every-2-sec-until-running lc-db 1
echo -n "Next >>"
read text
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "3. Check in Browser, even after restart pod User is persistent ${NC}"
echo -n ">>"
read text
clear
echo -e "${GREEN}Going to curl the Service on localhost:${NC}"
curl-each-node
