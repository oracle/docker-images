LB_IP=<external ip to access the k8s cluster on port 9055, 9060 and 2071 to 2075 from outside the cluster>

helm install \
  --set imagePullSecrets="<your-secret-file-for-container-registry-access>" \
  --set TuxLoadBalIP="${LB_IP}" \
  tuxedows-helm-install tuxedows-helm-chart
