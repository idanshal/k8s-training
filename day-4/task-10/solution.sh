#!/bin/bash

source ../../tools/solution_utils.sh

write-pv-yaml(){
  rm -f pv.yaml
  cat > pv.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs
spec:
  storageClassName: my-storage
  capacity:
    storage: 10Mi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 172.17.0.1
    path: "/mnt/nfs_share"

EOF
  cat pv.yaml
}

write-pvc-yaml(){
  rm -f pvc.yaml
  cat > pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-uploads
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Mi
EOF
  cat pvc.yaml
}

write-app-deploy-yaml(){
  rm -f app-deploy.yaml
  cat > app-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lc-app # The name of your deployment
  labels:
    app: lc-app  # The label of your deployment
spec:
  replicas: 1 # Number of replicated pods
  selector:
    matchLabels:
      app: lc-app # defines how the Deployment finds which Pods to manage. Should match labels defined in the Pod template
  template:
    metadata:
      labels:
        app: lc-app # The label of the pod to match selectors
    spec:
      containers:
      - name: lc-app # The container name
        image: eylonmalin/lets-chat-app:v1 # The DockerHub image
        ports:
        - containerPort: 8080 # Open pod port 80 for the container
        livenessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
        readinessProbe:
          httpGet:
            path: /login
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 1
        env: # [OPTIONAL] add environments values
        - name: MONGO_HOST
          value: lc-db
        - name: MONGO_PORT
          value: "27017"
        - name: MONGO_USER
          valueFrom:
            secretKeyRef:
              name: lc-db
              key: username
        - name: MONGO_PASS
          valueFrom:
            secretKeyRef:
              name: lc-db
              key: password
        volumeMounts:
        - name: settings-config
          mountPath: /usr/src/app/config
        - name: secret-keys
          mountPath: /usr/src/app/docker
        - name: uploads
          mountPath: /usr/src/app/uploads
      volumes:
        - name: settings-config
          configMap:
            name: lc-app
        - name: secret-keys
          secret:
            secretName: lc-app
            defaultMode: 256
        - name: uploads
          persistentVolumeClaim:
            claimName: app-uploads

EOF
  cat app-deploy.yaml
}


show-nfs-server(){
  echo -n "\$ ps -ef | grep nfs"
  read text
  ps -ef | grep nfs
  read text
  echo -n "\$ sudo cat /etc/exports"
  read text
  sudo cat /etc/exports
}

mkdir-in-node(){
  echo -n "\$ docker exec -it kind-worker mkdir -p /letschat/data"
  read text
  docker exec -it kind-worker mkdir -p /letschat/data
  echo -n "\$ docker exec -it kind-worker ls -l /"
  read text
  docker exec -it kind-worker ls -l
  echo -n "\$ docker exec -it kind-worker ls -l /letschat"
  read text
  docker exec -it kind-worker ls -l /letschat
  echo -n "\$ docker exec -it kind-worker ls -l /letschat/data"
  read text
  docker exec -it kind-worker ls -l /letschat/data
}


clear
echo
echo "████████╗  █████╗  ███████╗ ██╗  ██╗   ███╗   █████╗      "
echo "╚══██╔══╝ ██╔══██╗ ██╔════╝ ██║ ██╔╝    ██║  ██╔══██╗ ██╗ "
echo "   ██║    ███████║ ███████╗ █████╔╝     ██║   █   █╔╝ ╚═╝ "
echo "   ██║    ██╔══██║ ╚════██║ ██╔═██╗     ██║  ██   ██╗ ██╗ "
echo "   ██║    ██║  ██║ ███████║ ██║  ██╗    ██║  ╚█████╔╝ ╚═╝ "
echo "   ╚═╝    ╚═╝  ╚═╝ ╚══════╝ ╚═╝  ╚═╝    ╚═╝   ╚════╝      "
echo

echo -e "${RED}Make sure you run this solution after you successfully executed Task 9 solution${NC}"
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "1. Create PersistentVolumeClaim for the PersistentVolume ${NC}"
echo -n ">>"
read text
echo -e "${GREEN}Writing pvc.yaml file:${NC}"
echoDashes
write-pvc-yaml
echoDashes
next
echo -e "${GREEN}Update the pvc:${NC}"
apply-change pvc.yaml
read text
kubectl get pvc
read text
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "2. Update the Lets-Chat-App deployment by adding it as a Volume the PersistentVolumeClaim ${NC}"
echo -n ">>"
read text
echo -e "${GREEN}Writing app-deploy.yaml file:${NC}"
echoDashes
write-app-deploy-yaml
echoDashes
next
echo -e "${GREEN}Update the app Deployment:${NC}"
apply-change app-deploy.yaml
read text
clear
echo -ne "${GREEN}Verify the pods are ready, ${NC}"
get-pods-every-2-sec-until-running lc-app 1
echo -n "Next >>"
read text
echo -e "${ORANGE}---------------------------------------------------------------------------------------------"
echo -e "3. Check in Browser, even after restart - the uploads in chat remain ${NC}"
echo -n ">>"
read text
clear
echo -e "${GREEN}Going to curl the Service on localhost:${NC}"
curl-each-node
read text

