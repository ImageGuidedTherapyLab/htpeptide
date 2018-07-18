
GMX=gmx -nobackup


Peptide_assembly/2_Creating_coordinates/TYR-ALA-TYR_aa.pdb:
	cd $(@D); ./make_peptides.sh

#Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR.top: Peptide_assembly/2_Creating_coordinates/TYR-ALA-TYR_aa.pdb
Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR.top:
	cd $(@D); ./martinize.py -f ../2_Creating_coordinates/TYR-ALA-TYR_aa.pdb -name TYR-ALA-TYR -o TYR-ALA-TYR.top -x TYR-ALA-TYR.pdb -ff martini22 -nt -ss EEE
	@echo -FIXME- automate  output of solvate to number of water molecules in topology file
	sed -i "s/martini.itp/martini_v2.2.itp/g;s/1$$/100\n/g;" $@
	echo W      3234 >>  $@
	sed -i '2 i\#include "martini_v2.0_ions.itp"'  $@

Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR_box.gro: Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR.top 
	cd $(@D); $(GMX) insert-molecules -box 8 8 8 -nmol 100 -ci TYR-ALA-TYR.pdb -radius 0.4 -o TYR-ALA-TYR_box.gro

Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR_water.gro: Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR_box.gro
	cd $(@D); $(GMX) solvate  -cp $(<F) -cs water-80A_eq.gro -radius 0.21 -o $(@F)
	cd $(@D); $(GMX) grompp -f tripep_water_min.mdp -p TYR-ALA-TYR.top -c TYR-ALA-TYR_water.gro -o TYR-ALA-TYR_genion.tpr
	cd $(@D); $(GMX) genion -s TYR-ALA-TYR_genion.tpr -pname NA+ -nname CL- -neutral -o $(@F)

Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_min.tpr: Peptide_assembly/3_Coarse-graining/TYR-ALA-TYR_water.gro
	cd $(@D); $(GMX) grompp -f tripep_water_min.mdp -p ../3_Coarse-graining/TYR-ALA-TYR.top -c ../3_Coarse-graining/TYR-ALA-TYR_water.gro -o TYR-ALA-TYR_min.tpr

Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_min.trr: Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_min.tpr
	cd $(@D); $(GMX) mdrun -deffnm TYR-ALA-TYR_min -v

Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_eq.tpr: Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_min.trr Peptide_assembly/4_Running_simulations/tripep_water_eq.mdp
	cd $(@D); $(GMX) grompp -f tripep_water_eq.mdp -p ../3_Coarse-graining/TYR-ALA-TYR.top -c TYR-ALA-TYR_min.gro -o TYR-ALA-TYR_eq.tpr -maxwarn 1

Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_eq.trr: Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_eq.tpr 
	cd $(@D); $(GMX) mdrun -deffnm TYR-ALA-TYR_eq -v

Peptide_assembly/4_Running_simulations/TYR-ALA-TYR_eq.view:
	vglrun /opt/apps/VMD/vmd-1.9.3-opengl/vmd/vmd_LINUXAMD64 $(@D)/TYR-ALA-TYR_min.gro $(@D)/TYR-ALA-TYR_eq.xtc

Peptide_assembly/5_Analysis/TYR-ALA-TYR_clustered.gro: 
	cd $(@D); echo 1 1 1 | $(GMX) trjconv -f ../4_Running_simulations/TYR-ALA-TYR_eq.gro -s ../4_Running_simulations/TYR-ALA-TYR_eq.tpr -pbc cluster -center -o TYR-ALA-TYR_clustered.gro
	cd $(@D); echo 1 1 1 | $(GMX) trjconv -f ../4_Running_simulations/TYR-ALA-TYR_eq.xtc -s ../4_Running_simulations/TYR-ALA-TYR_eq.tpr -pbc cluster -center -o TYR-ALA-TYR_clustered.xtc

Peptide_assembly/5_Analysis/TYR-ALA-TYR_clustered.view: 
	vglrun /opt/apps/VMD/vmd-1.9.3-opengl/vmd/vmd_LINUXAMD64 $(@D)/TYR-ALA-TYR_clustered.gro $(@D)/TYR-ALA-TYR_clustered.xtc

Peptide_assembly/5_Analysis/TYR-ALA-TYR_sasa_init.xvg:
	cd $(@D); echo 1 | $(GMX) sasa -f ../4_Running_simulations/TYR-ALA-TYR_min.gro -s ../4_Running_simulations/TYR-ALA-TYR_min.tpr -o TYR-ALA-TYR_sasa_init.xvg

Peptide_assembly/5_Analysis/TYR-ALA-TYR_sasa_end.xvg:
	cd $(@D); echo 1 | $(GMX) sasa -f TYR-ALA-TYR_clustered.gro -s ../4_Running_simulations/TYR-ALA-TYR_eq.tpr -o TYR-ALA-TYR_sasa_end.xvg
