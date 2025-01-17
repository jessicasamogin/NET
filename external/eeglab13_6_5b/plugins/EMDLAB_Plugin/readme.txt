
 EMDLAB Plug-in 


== Description ==

 EMDLAB is an extensible plug-in for the EEGLAB toolbox, which is an open software environment for electrophysiological data analysis.EMDLAB can be used to perform, easily and effectively, four common types of EMD: plain EMD, Ensemble EMD (EEMD), weighted sliding EMD (wSEMD) and multivariate EMD (MEMD) on EEG data. EMDLAB gains an advantage over other open-source toolboxes by exploiting the advantageous visualization capabilities of EEGLAB for extracted intrinsic mode functions (IMFs) and Event-Related Modes (ERMs) of the signal. EMDLAB is a reliable, efficient, and automated solution for extracting and visualizing the extracted IMFs and ERMs by EMD algorithms in EEG study.
This code was implemented mainely based on EEGLAB toolbox code. 

== Requirements ==

- Matlab

   - The Matlab Signal Processing Toolbox is required. This plug-in has been tested with versions (R2012a) and above.

- EEGLAB Toolbox

    EMDLAB has mainly been tested so far with versions 10.2.2.4b and 13_4_4b. 


== Installation ==

To begin using EMDLAB plug-ing, 

- First make sure that EEGLAB is not running and remove the old version of the plugin if it is present in either directory.

- Uncompress the downloaded plug-in file in the main EEGLAB "plugins" folder. For example, you might place EMDLAB in a path like this:

       Documents > MATLAB > eeglab13_4_4b > plugins

- Then restart EEGLAB. During start-up, EEGLAB should print the following on the Matlab command line:

    EEGLAB: adding plugin function "eegplugin_EMDLAB"

- The plug-in will typically have added one item to the EEGLAB GUI as a new menu called EMDLAB. 


== Uninstallation ==

- To make EEGLAB ignore a downloaded plug-in, simply move or remove its folder from the EEGLAB plugins (or main) directory and restart EEGLAB. 


== Sample Data ==

- There is an EEG sample data provided with the EMDLAB plug-in.

== Citation==

K. Al-Subaria and S. Al-Baddaia et al.. EMDLAB: A toolbox for analysis of single-trial EEG dynamics using empirical mode decomposition. Journal of Neuroscience Methods. Vol.253.pp.193-205, 2015.
 
