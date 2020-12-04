#!/bin/bash

# not done yet but basic idea since sgdisk -Z is no longer sufficient

dmsetup ls
dmsetup remove $X

# e.g. 
# dmsetup remove ceph--98dfc177--3fe1--4248--9333--c2110f854c76-osd--data--4284de94--753a--4bfc--a27e--8fa79f1ab42b

lsblk
sgdisk -Z $Y

