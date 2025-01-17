%-----------------------------------------------------------------------
% Job configuration created by cfg_util (rev $Rev$)
%-----------------------------------------------------------------------
matlabbatch{1}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.name = 'FA Images';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.tag = 'PFA';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{1}.menu_cfg.menu_entry.conf_files.num = [1 Inf];
matlabbatch{1}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{1}.menu_cfg.menu_entry.conf_files.help = {'Enter the FA images for all subjects.'};
matlabbatch{1}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{2}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.name = 'b0 Images';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.tag = 'Pb0';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{2}.menu_cfg.menu_entry.conf_files.num = [0 Inf];
matlabbatch{2}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{2}.menu_cfg.menu_entry.conf_files.help = {'Enter the b0 images for all subjects.'};
matlabbatch{2}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{3}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.name = 'Mean DW Images';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.tag = 'Pmean';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{3}.menu_cfg.menu_entry.conf_files.num = [0 Inf];
matlabbatch{3}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{3}.menu_cfg.menu_entry.conf_files.help = {'Enter the FA images for all subjects.'};
matlabbatch{3}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{4}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.name = 'External b0 Template';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.tag = 'PGb0';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{4}.menu_cfg.menu_entry.conf_files.num = [0 1];
matlabbatch{4}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{4}.menu_cfg.menu_entry.conf_files.help = {'Enter external template (or done for none)'};
matlabbatch{4}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{5}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.name = 'External FA Template';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.tag = 'PGFA';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{5}.menu_cfg.menu_entry.conf_files.num = [0 1];
matlabbatch{5}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{5}.menu_cfg.menu_entry.conf_files.help = {'Enter external template (or done for none)'};
matlabbatch{5}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{6}.menu_cfg.menu_entry.conf_files.type = 'cfg_files';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.name = 'External LFA Template';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.tag = 'PGLFA';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.filter = 'image';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.ufilter = '.*';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.dir = '';
matlabbatch{6}.menu_cfg.menu_entry.conf_files.num = [0 1];
matlabbatch{6}.menu_cfg.menu_entry.conf_files.check = [];
matlabbatch{6}.menu_cfg.menu_entry.conf_files.help = {'Enter external template (or done for none)'};
matlabbatch{6}.menu_cfg.menu_entry.conf_files.def = [];
matlabbatch{7}.menu_cfg.menu_entry.conf_const.type = 'cfg_const';
matlabbatch{7}.menu_cfg.menu_entry.conf_const.name = 'CT: No LFA Registration';
matlabbatch{7}.menu_cfg.menu_entry.conf_const.tag = 'NCT';
matlabbatch{7}.menu_cfg.menu_entry.conf_const.val = {0};
matlabbatch{7}.menu_cfg.menu_entry.conf_const.check = [];
matlabbatch{7}.menu_cfg.menu_entry.conf_const.help = {};
matlabbatch{7}.menu_cfg.menu_entry.conf_const.def = [];
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.type = 'cfg_menu';
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.name = 'SCT: Finale LFA-Registration?';
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.tag = 'SCT';
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.labels = {
                                                       'off'
                                                       'on'
                                                       }';
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.values = {
                                                       0
                                                       1
                                                       }';
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.check = [];
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.help = {};
matlabbatch{8}.menu_cfg.menu_entry.conf_menu.def = [];
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.type = 'cfg_branch';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.name = 'Multi-Contrast: b0, FA and LFA';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.tag = 'MC';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1) = cfg_dep;
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1).tname = 'Val Item';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1).tgt_spec = {};
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1).sname = 'Files: External b0 Template (cfg_files)';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1).src_exbranch = substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{1}(1).src_output = substruct('()',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1) = cfg_dep;
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1).tname = 'Val Item';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1).tgt_spec = {};
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1).sname = 'Files: External FA Template (cfg_files)';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1).src_exbranch = substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{2}(1).src_output = substruct('()',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1) = cfg_dep;
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1).tname = 'Val Item';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1).tgt_spec = {};
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1).sname = 'Files: External LFA Template (cfg_files)';
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1).src_exbranch = substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.val{3}(1).src_output = substruct('()',{1});
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.check = [];
matlabbatch{9}.menu_cfg.menu_struct.conf_branch.help = {'First Entry: b0, second: FA, third: LFA (selection of each template is optional: "done for none")'};
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.type = 'cfg_choice';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.name = 'Single-Contrast: b0, FA or LFA';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.tag = 'SC';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1) = cfg_dep;
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1).tname = 'Values Item';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1).tgt_spec = {};
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1).sname = 'Files: External b0 Template (cfg_files)';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_exbranch = substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_output = substruct('()',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1) = cfg_dep;
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1).tname = 'Values Item';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1).tgt_spec = {};
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1).sname = 'Files: External FA Template (cfg_files)';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_exbranch = substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_output = substruct('()',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1) = cfg_dep;
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1).tname = 'Values Item';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1).tgt_spec = {};
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1).sname = 'Files: External LFA Template (cfg_files)';
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1).src_exbranch = substruct('.','val', '{}',{6}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.values{3}(1).src_output = substruct('()',{1});
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.check = [];
matlabbatch{10}.menu_cfg.menu_struct.conf_choice.help = {'First Entry: b0, second: FA, third: LFA'};
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.type = 'cfg_choice';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.name = 'ET: Single-Contrast or Multi-Contrast (SCT or MCT)?';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.tag = 'ET';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1) = cfg_dep;
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1).tname = 'Values Item';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1).tgt_spec = {};
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1).sname = 'Choice: Single-Contrast: b0, FA or LFA (cfg_choice)';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_exbranch = substruct('.','val', '{}',{10}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_output = substruct('()',{1});
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1) = cfg_dep;
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1).tname = 'Values Item';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1).tgt_spec = {};
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1).sname = 'Branch: Multi-Contrast: b0, FA and LFA (cfg_branch)';
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_exbranch = substruct('.','val', '{}',{9}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_output = substruct('()',{1});
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.check = [];
matlabbatch{11}.menu_cfg.menu_struct.conf_choice.help = {};
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.type = 'cfg_choice';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.name = 'CT: Normal or Symmetrisized (NCT or SCT)?';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.tag = 'CT';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1) = cfg_dep;
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1).tname = 'Values Item';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1).tgt_spec = {};
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1).sname = 'Const: CT: No LFA Registration (cfg_const)';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_exbranch = substruct('.','val', '{}',{7}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_output = substruct('()',{1});
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1) = cfg_dep;
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1).tname = 'Values Item';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1).tgt_spec = {};
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1).sname = 'Menu: SCT: Finale LFA-Registration? (cfg_menu)';
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_exbranch = substruct('.','val', '{}',{8}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_output = substruct('()',{1});
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.check = [];
matlabbatch{12}.menu_cfg.menu_struct.conf_choice.help = {};
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.type = 'cfg_choice';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.name = 'Customized or External Template (CT or ET)?';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.tag = 'templ';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1) = cfg_dep;
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1).tname = 'Values Item';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1).tgt_spec = {};
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1).sname = 'Choice: CT: Normal or Symmetrisized (NCT or SCT)? (cfg_choice)';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_exbranch = substruct('.','val', '{}',{12}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{1}(1).src_output = substruct('()',{1});
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1) = cfg_dep;
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1).tname = 'Values Item';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1).tgt_spec = {};
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1).sname = 'Choice: ET: Single-Contrast or Multi-Contrast (SCT or MCT)? (cfg_choice)';
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_exbranch = substruct('.','val', '{}',{11}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.values{2}(1).src_output = substruct('()',{1});
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.check = [];
matlabbatch{13}.menu_cfg.menu_struct.conf_choice.help = {};
matlabbatch{14}.menu_cfg.menu_entry.conf_const.type = 'cfg_const';
matlabbatch{14}.menu_cfg.menu_entry.conf_const.name = 'b0';
matlabbatch{14}.menu_cfg.menu_entry.conf_const.tag = 'b0';
matlabbatch{14}.menu_cfg.menu_entry.conf_const.val = {1};
matlabbatch{14}.menu_cfg.menu_entry.conf_const.check = [];
matlabbatch{14}.menu_cfg.menu_entry.conf_const.help = {};
matlabbatch{14}.menu_cfg.menu_entry.conf_const.def = [];
matlabbatch{15}.menu_cfg.menu_entry.conf_const.type = 'cfg_const';
matlabbatch{15}.menu_cfg.menu_entry.conf_const.name = 'FA';
matlabbatch{15}.menu_cfg.menu_entry.conf_const.tag = 'FA';
matlabbatch{15}.menu_cfg.menu_entry.conf_const.val = {0};
matlabbatch{15}.menu_cfg.menu_entry.conf_const.check = [];
matlabbatch{15}.menu_cfg.menu_entry.conf_const.help = {};
matlabbatch{15}.menu_cfg.menu_entry.conf_const.def = [];
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.type = 'cfg_repeat';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.name = 'Normalisation Step(s)';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.tag = 'steps';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1) = cfg_dep;
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1).tname = 'Values Item';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1).tgt_spec = {};
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1).sname = 'Const: b0 (cfg_const)';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1).src_exbranch = substruct('.','val', '{}',{14}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{1}(1).src_output = substruct('()',{1});
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1) = cfg_dep;
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1).tname = 'Values Item';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1).tgt_spec = {};
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1).sname = 'Const: FA (cfg_const)';
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1).src_exbranch = substruct('.','val', '{}',{15}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.values{2}(1).src_output = substruct('()',{1});
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.num = [1 Inf];
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.forcestruct = true;
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.check = [];
matlabbatch{16}.menu_cfg.menu_struct.conf_repeat.help = {};
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.type = 'cfg_entry';
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.name = 'Number of Iterations';
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.tag = 'niter';
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.strtype = 'w';
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.extras = [];
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.num = [1 1];
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.check = [];
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.help = {};
matlabbatch{17}.menu_cfg.menu_entry.conf_entry.def = [];
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.type = 'cfg_branch';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.name = 'Normalisation Procedure';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.tag = 'norm';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1) = cfg_dep;
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1).tname = 'Val Item';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1).tgt_spec = {};
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1).sname = 'Choice: Customized or External Template (CT or ET)? (cfg_choice)';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1).src_exbranch = substruct('.','val', '{}',{13}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{1}(1).src_output = substruct('()',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1) = cfg_dep;
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1).tname = 'Val Item';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1).tgt_spec = {};
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1).sname = 'Repeat: Normalisation Step(s) (cfg_repeat)';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1).src_exbranch = substruct('.','val', '{}',{16}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{2}(1).src_output = substruct('()',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1) = cfg_dep;
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1).tname = 'Val Item';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1).tgt_spec = {};
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1).sname = 'Entry: Number of Iterations (cfg_entry)';
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1).src_exbranch = substruct('.','val', '{}',{17}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.val{3}(1).src_output = substruct('()',{1});
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.check = [];
matlabbatch{18}.menu_cfg.menu_struct.conf_branch.help = {'In the first entry the choice between customized and external template (CT or ET) is performed.'};
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.type = 'cfg_exbranch';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.name = 'FAVBS Normalisation';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.tag = 'favbs_norm';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1) = cfg_dep;
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1).tname = 'Val Item';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1).tgt_spec = {};
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1).sname = 'Files: FA Images (cfg_files)';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1).src_exbranch = substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{1}(1).src_output = substruct('()',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1) = cfg_dep;
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1).tname = 'Val Item';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1).tgt_spec = {};
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1).sname = 'Files: b0 Images (cfg_files)';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1).src_exbranch = substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{2}(1).src_output = substruct('()',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1) = cfg_dep;
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1).tname = 'Val Item';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1).tgt_spec = {};
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1).sname = 'Files: Mean DW Images (cfg_files)';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1).src_exbranch = substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{3}(1).src_output = substruct('()',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1) = cfg_dep;
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1).tname = 'Val Item';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1).tgt_spec = {};
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1).sname = 'Branch: Normalisation Procedure (cfg_branch)';
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1).src_exbranch = substruct('.','val', '{}',{18}, '.','val', '{}',{1}, '.','val', '{}',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.val{4}(1).src_output = substruct('()',{1});
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.prog = @(job)tbxdti_run_favbs_norm('run',job);
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.vout = @(job)tbxdti_run_favbs_norm('vout',job);
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.check = @(job)tbxdti_run_favbs_norm('check','files',job);
matlabbatch{19}.menu_cfg.menu_struct.conf_exbranch.help = {};
