** 12.4 Развертывание кластера на собственных серверах, лекция 2


Ресурсы в облаке:

![изображение](https://user-images.githubusercontent.com/98019531/211319873-fb2e8f3b-4481-485b-a4f8-5d7fd825e6bf.png)


Изменённый inventory.ini для кубспрея под наши конкретные нужды:

```
# ## Configure 'ip' variable to bind kubernetes services on a
# ## different ip than the default iface
# ## We should set etcd_member_name for etcd cluster. The node that is not a etcd member do not need to set the value, or can set the empty string value.
[all]
master ansible_host=158.160.32.223  # ip=10.3.0.1 etcd_member_name=etcd1
work1 ansible_host=130.193.37.49  # ip=10.3.0.2 etcd_member_name=etcd2
work2 ansible_host=158.160.45.233  # ip=10.3.0.3 etcd_member_name=etcd3
work3 ansible_host=84.252.130.214  # ip=10.3.0.4 etcd_member_name=etcd4
work4 ansible_host=51.250.88.148  # ip=10.3.0.5 etcd_member_name=etcd5

# ## configure a bastion host if your nodes are not directly reachable
# [bastion]
# bastion ansible_host=x.x.x.x ansible_user=some_user

[kube_control_plane]
master

[etcd]
master

[kube_node]
work1
work2
work3
work4

[calico_rr]

[k8s_cluster:children]
kube_control_plane
kube_node
calico_rr
```

Рекап кубспрея:

![изображение](https://user-images.githubusercontent.com/98019531/211320002-80ef0e29-d0da-43b8-bcb6-a9d07a047b44.png)


Наш кластер (c деплоем одного пода энжинкса):

![изображение](https://user-images.githubusercontent.com/98019531/211320836-b10bdee0-0499-434f-a4b8-4e85f79d0a73.png)
