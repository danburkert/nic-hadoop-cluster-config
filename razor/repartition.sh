for disk in $(ls /dev/sd[b-h])
do
cat <<EOF | fdisk $disk
d
1
d
2
d
3
d
4
d
5
d
6
d
7
d
8
d
9
n
p



w
EOF
done
