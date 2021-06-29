linux_ver=5.12.13
_subarch=17
_gcc_more_v=20210610
_ckpatchversion=1
_ckpatch=patch-5.12-${_ckpatchversion}

wget -c https://www.kernel.org/pub/linux/kernel/v5.x/linux-${linux_ver}.tar.xz
wget -c https://github.com/graysky2/kernel_compiler_patch/archive/${_gcc_more_v}.tar.gz
wget -c http://ck.kolivas.org/patches/5.0/5.12/5.12-ck${_ckpatchversion}/$_ckpatch.xz
tar -xpvf linux-${linux_ver}.tar.xz
tar -xpvf ${_gcc_more_v}.tar.gz
xz -d ${_ckpatch}.xz

cd linux-${linux_ver}
scripts/setlocalversion --save-scmversion
local src
for src in "${source[@]}"; do
  	src="${src%%::*}"
  	src="${src##*/}"
  	[[ $src = 0*.patch ]] || continue
  	echo "Applying patch $src..."
  	patch -Np1 < "../$src"
done 

cp ../config.debian .config

scripts/config --disable CONFIG_DEBUG_INFO
scripts/config --disable CONFIG_CGROUP_BPF
scripts/config --disable CONFIG_BPF_LSM
scripts/config --disable CONFIG_BPF_PRELOAD
scripts/config --disable CONFIG_BPF_LIRC_MODE2
scripts/config --disable CONFIG_BPF_KPROBE_OVERRIDE

scripts/config --enable CONFIG_PSI_DEFAULT_DISABLED

scripts/config --disable CONFIG_LATENCYTOP
scripts/config --disable CONFIG_SCHED_DEBUG

scripts/config --disable CONFIG_KVM_WERROR

sed -i -re "s/^(.EXTRAVERSION).*$/\1 = /" "../${_ckpatch}"

patch -Np1 -i ../"${_ckpatch}"

make olddefconfig

patch -Np1 -i "../kernel_compiler_patch-${_gcc_more_v}/more-uarches-for-kernel-5.8+.patch"

if [[ -n "${_subarch}" ]]; then
	yes "${_subarch}" | make oldconfig
fi
make -s kernelrelease > version

make deb-pkg INSTALL_MOD_STRIP=1 LOCALVERSION=-ck-uksm KDEB_PKGVERSION=$(make kernelversion)-1 -j40
