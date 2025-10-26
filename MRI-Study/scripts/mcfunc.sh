#/bin/csh
#
set image = $1
set tdir = $2
set homedir = `pwd`
set imprefix = `remove_ext ${image}`
echo "cd ${tdir}"
cd ${tdir}
echo "Running MCFlirt on ${image}"
echo "mcflirt -in ${imprefix} -o ${imprefix}_mc -mats -plots -rmsrel -rmsabs"
mcflirt -in ${imprefix} -o ${imprefix}_mc -mats -plots -rmsrel -rmsabs
echo "Cleaning up mc files"
mkdir mc
echo "mv -f ${imprefix}_mc.mat ${imprefix}_mc_abs.rms ${imprefix}_mc_abs_mean.rms ${imprefix}_mc_rel.rms ${imprefix}_mc_rel_mean.rms ${tdir}/mc/"
mv -f ${imprefix}_mc.mat ${imprefix}_mc_abs.rms ${imprefix}_mc_abs_mean.rms ${imprefix}_mc_rel.rms ${imprefix}_mc_rel_mean.rms ${tdir}/mc/
echo "mv -f ${imprefix}_mc.par ${imprefix}_mc.par.txt"
mv -f ${imprefix}_mc.par ${tdir}/mc/${imprefix}_mc.par.txt
echo "Creating motion plots"
echo "fsl_tsplot -i ${tdir}/mc/${imprefix}_mc.par.txt -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o ${tdir}/mc/${imprefix}_mc_rot.png"
fsl_tsplot -i ${tdir}/mc/${imprefix}_mc.par.txt -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o ${tdir}/mc/${imprefix}_mc_rot.png
echo "fsl_tsplot -i ${tdir}/mc/${imprefix}_mc.par.txt -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o ${tdir}/mc/${imprefix}_mc_trans.png"
fsl_tsplot -i ${tdir}/mc/${imprefix}_mc.par.txt -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o ${tdir}/mc/${imprefix}_mc_trans.png
echo "fsl_tsplot -i ${tdir}/mc/${imprefix}_mc_abs.rms,${tdir}/mc/${imprefix}_mc_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o ${tdir}/mc/${imprefix}_mc_disp.png"
fsl_tsplot -i ${tdir}/mc/${imprefix}_mc_abs.rms,${tdir}/mc/${imprefix}_mc_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o ${tdir}/mc/${imprefix}_mc_disp.png
echo "Done.  Motion plots in ${tdir}/mc/*.png"
cd ${homedir}
