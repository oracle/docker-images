#!/bin/sh

echo "called" >> scaleUpAction.log

num_ms=`curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -X GET https://kubernetes/apis/apps/v1beta1/namespaces/default/statefulsets/${MS_STATEFULSET_NAME}/status | grep -m 1 replicas| sed 's/.*\://; s/,.*$//'`

echo "current number of servers is $num_ms" >> scaleUpAction.log

new_ms=$(($num_ms + 1))

echo "new_ms is $new_ms" >> scaleUpAction.log

curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -X PATCH -H "Content-Type: application/strategic-merge-patch+json" -d '{"spec":{"replicas":'"$new_ms"'}}' https://kubernetes/apis/apps/v1beta1/namespaces/default/statefulsets/${MS_STATEFULSET_NAME}

