<a id="toc"></a>
# Contents
1.) [Summary](#summary)  
2.) [Usage](#usage)  
3.) [Definitions](#definitions)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.1) [Default Mode Circuit](#dmn)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.2) [Salience Circuit](#salience)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.3) [Attention Circuit](#attention)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.4) [Negative Affect Circuit: Sad](#neg_affect_sad)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.5) [Negative Affect Circuit: Threat Conscious](#neg_affect_threat_conscious)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.6) [Negative Affect Circuit: Threat Nonconscious](#neg_affect_threat_nonconscious)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.7) [Positive Affect Circuit: Happy](#pos_affect_happy)  
&nbsp;&nbsp;&nbsp;&nbsp; 3.8) [Cognitive Control Circuit](#cognitive_control)  

<a id="summary"></a>
## [^](#toc) Summary  

This folder includes the ROI regions used in the Williams 2021 Biological Psychiatry paper:

<b>Mapping neural circuit biotypes to symptoms and behavioral dimensions of depression and anxiety</b>

Andrea N Goldstein-Piekarski<sup>†</sup>, Tali M Ball<sup>†</sup>, Zoe Samara<sup>‡</sup>, Brooke R Staveland<sup>‡</sup>, Arielle S. Keller<sup>‡</sup>, Scott L Fleming<sup>‡</sup>, Katherine A Grisanzio<sup>‡</sup>, Bailey Holt-Gosselin<sup>‡</sup>, Patrick Stetz<sup>‡</sup>, Jun Ma<sup>‡</sup>, & Leanne M Williams

<a id="usage"></a>
## [^](#toc) Usage

Please include the following citation:

>Goldstein-Piekarski A, Ball T, Samara Z, Staveland B, Keller A, Fleming S, Grisanzio K, Holt-Gosselin B, Stetz P, Ma J, & Williams L. Mapping neural circuit biotypes to symptoms and behavioral dimensions of depression and anxiety. Biological Psychiatry. 2021; doi: [https://doi.org/10.1016/j.biopsych.2021.06.024](https://doi.org/10.1016/j.biopsych.2021.06.024 ) 

To download the files, please click [here](https://github.com/WilliamsPANLab/2021-masks/archive/refs/heads/master.zip) or clone the repository


<a id="definitions"></a>
## [^](#toc) Definitions

<a id="dmn"></a>
#### [^](#toc) Default Mode Circuit
| Circuit Type | Condition | Task Contrast | Neurosynth Search criteria |
| ------ | ------ | ----- | ----- |
| Intrinsic | Task-free | --- | Terms = "default mode"; "resting state"; <br><br> Number of studies = 516; 825 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| amPFC   | 22.0    | -2, 50, -6 | `Medial_amPFC_DefaultModeNetwork_n2_50_n6.nii.gz` |
| AG L    | 26.1    | -46, -70, 32 | `Left_AG_DefaultModeNetwork_n46_n70_32.nii.gz` |
| AG R    | 20.6    | 50, -62, 26 | `Right_AG_DefaultModeNetwork_50_n62_26.nii.gz` |
| PCC     | 29.8    | 0, -50, 28 | `Medial_PCC_DefaultModeNetwork_0_n50_28.nii.gz` |

<br>

---

<a id="salience"></a>
#### [^](#toc) Salience Circuit
| Circuit Type |   Condition | Task Contrast | Neurosynth Search criteria |
| --- | --- | --- | --- | 
| Intrinsic | Task-free | --- | Terms = "salience network"; "salience" <br><br> Number of studies = 60; 269 <br><br> Search Date = 6.4.17 |
 
 <br>
 
| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- | 
| aI L |   11.9 |   -38, 14, -6 | `Left_antInsula_Salience_n38_14_n6.nii.gz` |
| aI R |   14.8 |   38, 18, 2 | `Right_antInsula_Salience_38_18_2.nii.gz` |
| Amygdala L  |    6.9  |   AAL | `Left_Amygdala_Salience.nii.gz` |
| Amygdala R  |    14.7  |  AAL | `Right_Amygdala_Salience.nii.gz` |

 <br>

---

<a id="attention"></a>
#### [^](#toc) Attention Circuit
 | Circuit Type |   Condition | Task Contrast | Neurosynth Search criteria |
| --- | --- | --- | --- | 
| Intrinsic | Task-free | --- | Terms = "frontoparietal network"; "attention" <br><br> Number of studies = 1447; 79 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| msPFC  | 10.4  |  -2, 14, 52 | `Medial_msPFC_Attention_n2_14_52.nii.gz` |
| LPFC L | 13.9  |  -44, 6, 32 | `Left_lPFC_Attention_n44_6_32.nii.gz` |
| LPFC R | 11.3  |  50, 10, 28 | `Right_lPFC_Attention_50_10_28.nii.gz` |
| aIPL L | 10.4  |  -30, -54, 40 | `Left_aIPL_Attention_n30_n54_40.nii.gz` |
| aIPL R | 10.4  |  38, -56, 48 | `Right_aIPL_Attention_38_n56_48.nii.gz` |
| Precuneus L  |   13.0  |  -14, -66, 52 | `Left_precuneus_Attention_n14_n66_52.nii.gz` |
| Precuneus R  |   11.3  |  18, -68, 52 | `Right_precuneus_Attention_18_n68_52.nii.gz` |

<br>

---

<a id="neg_affect_sad"></a>
#### [^](#toc) Negative Affect Circuit: Sad
| Circuit Type | Condition | Task Contrast | Neurosynth Search Criteria |
| --- | --- | --- | --- |
| Task-evoked | Conscious Facial Emotion Viewing | Sad vs Neutral based on standardized facial emotion stimuli | Term = "threat" <br> Number of studies = 170 <br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| pgACC* | 6.3  |   6, 42, 4 | `Medial_pgACC_NegativeAffect_n6_42_n4.nii.gz` |
| aI L   | 17.4 |   -36, 20, -4 | `Left_antInsula_NegativeAffect_n36_20_n4.nii.gz` |
| aI R   | 16.1 |   38, 22, -4 | `Right_antInsula_NegativeAffect_38_22_n4.nii.gz` |
| Amygdala L |     28.4  |  AAL | `Left_Amygdala_NegativeAffect.nii.gz` |
| Amygdala R |     25.2  |  AAL | `Right_Amygdala_NegativeAffect.nii.gz` |

<br>

---

<a id="neg_affect_threat_conscious"></a>
#### [^](#toc) Negative Affect Circuit: Threat Conscious

| Circuit Type |  Condition | Task Contrast | Neurosynth Search Criteria |
| --- | --- | --- | --- |
| Task-evoked | Conscious Facial Emotion Viewing | Fear/Anger vs Neutral based on standardized facial emotion stimuli | Term = "threat" <br><br> Number of studies = 170 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| dACC   | 8.2    | 6, 22, 32 | `Medial_dACC_NegativeAffect_6_22_32.nii.gz` |
| Amygdala L      | 28.4 | AAL | `Left_Amygdala_NegativeAffect.nii.gz` |
| Amygdala R      | 25.2 | AAL | `Right_Amygdala_NegativeAffect.nii.gz` |

<br>

---

<a id="neg_affect_threat_nonconscious"></a>
#### [^](#toc) Negative Affect Circuit: Threat Nonconscious

| Circuit Type | Condition | Task Contrast | Neurosynth Search Criteria |
| --- | --- | --- | --- |
| Task-evoked | Nonconscious Facial Emotion Viewing | Fear/Anger vs Neutral based on standardized facial emotion stimuli | Term = "threat" <br><br> Number of studies = 170 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| sgACC  | 5.6    | 4, 26, -10 | `Medial_sgACC_NegativeAffect_4_26_n10.nii.gz` |
| Amygdala L     | 28.4   | AAL | `Left_Amygdala_NegativeAffect.nii.gz` |
| Amygdala R     | 25.2   | AAL | `Right_Amygdala_NegativeAffect.nii.gz` |

<br>

---

<a id="pos_affect_happy"></a>
#### [^](#toc) Positive Affect Circuit: Happy

| Circuit Type | Condition | Task Contrast | Neurosynth Search Criteria |
| --- | --- | --- | --- |
| Task-evoked | Conscious Facial Emotion Viewing | Happy vs Neutral based on standardized facial emotion stimuli | Terms = "monetary reward"; "reward" <br><br> Number of studies = 84; 671 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| vMPFC  | 13.1  |  -2, 56, -8 | `Medial_vmPFC_PositiveAffect_n2_56_n8.nii.gz` |
| Striatum L  |    14.0  |  FSL | `Left_vStriatum_PositiveAffect.nii.gz` |
| Striatum R  |    7.9   |  FSL | `Right_vStriatum_PositiveAffect.nii.gz` |

<br>

---

<a id="cognitive_control"></a>
#### [^](#toc) Cognitive Control Circuit   

| Circuit Type | Condition | Task Contrast | Neurosynth Search Criteria |
| --- | --- | --- | --- |
| Task-evoked | Go-NoGo task | No-Go vs. Go | Terms = "cognitive control" <br><br> Number of studies = 428 <br><br> Search Date = 6.4.17 |

<br>

| Region anatomy | Z Value | Template coordinates and definitions | Filename |
| --- | --- | --- | --- |
| dACC    | 20.0 |   0, 18, 46 | `Medial_dACC_CognitiveControl_0_18_46.nii.gz` |
| DLPFC L | 20.4 |   -44, 6, 32 | `Left_dlPFC_CognitiveControl_n44_6_32.nii.gz` |
| DLPFC R | 12.4 |   44, 34, 22 | `Right_dlPFC_CognitiveControl_44_34_22.nii.gz` |

*The pgACC peaks were defined by decreasing the minimum cluster distance in the 3dCluster algorithm.
