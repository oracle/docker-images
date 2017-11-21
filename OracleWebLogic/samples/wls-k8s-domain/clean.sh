kubectl delete -f  k8s/wls-stateful.yml --now=true
kubectl delete -f  k8s/wls-admin.yml --now=true 
kubectl delete -f  k8s/pvc.yml --now=true
kubectl delete -f  k8s/pv.yml --now=true
kubectl delete -f  k8s/secrets.yml --now=true

