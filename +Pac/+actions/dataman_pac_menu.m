function actions = dataman_pac_menu() 
    import xylobium.dledit.Action
    import Pac.actions.*

    ac_mu = Action("Mark RoIs/uncaging spot", @mark_rois_shot, false, true,"M");
    ac_mu.menu_position = "Pac";
    ac_mu.accept_multiple_dlocs = false;
    ac_mu.can_queue = false;
    ac_mu.can_execute_without_dloc = false;
    ac_mu.has_button = true;
    ac_mu.button_group = "Regions-of-interest";
    
    ac_sh = Action("Get uncaging info", @uncaging_info, false, true,"U");
    ac_sh.menu_position = "Pac";
    ac_sh.accept_multiple_dlocs = false;
    ac_sh.can_queue = true;
    ac_sh.can_execute_without_dloc = false;
    ac_sh.has_button = false;
    ac_sh.button_group = "Regions-of-interest";
         
    ac_rs = Action("Get rois w/ shot", @rois_w_shot, false, true,"G");
    ac_rs.menu_position = "Pac";
    ac_rs.accept_multiple_dlocs = false;
    ac_rs.can_queue = true;
    ac_rs.can_execute_without_dloc = false;
    ac_rs.has_button = false;
    
    ac_tr = Action("Targeted roi?", @has_target_roi, false, true,"T");
    ac_tr.menu_position = "Pac";
    ac_tr.accept_multiple_dlocs = false;
    ac_tr.can_queue = true;
    ac_tr.can_execute_without_dloc = false;
    ac_tr.has_button = false;
    
    ac_ps = Action("Plot & Save RoIs signal", @plot_rois, false, true);
    ac_ps.menu_position = "Pac";
    ac_ps.accept_multiple_dlocs = true;
    ac_ps.can_queue = false;
    ac_ps.can_execute_without_dloc = false;
    ac_ps.has_button = false;
    
    ac_pc = Action("Plot ROIs by channel", @plot_rois_by_channel, false, true);
    ac_pc.menu_position = "Pac";
    ac_pc.accept_multiple_dlocs = false;
    ac_pc.can_queue = true;
    ac_pc.can_execute_without_dloc = false;
    ac_pc.has_button = false;
    
    ac_pt = Action("Plot target ROI(s)", @plot_target, false, true);
    ac_pt.menu_position = "Pac";
    ac_pt.accept_multiple_dlocs = false;
    ac_pt.can_queue = true;
    ac_pt.can_execute_without_dloc = false;
    ac_pt.has_button = false;
    
    ac_ow = Action("Plot activity & rois overview", @plot_overview, false, true);
    ac_ow .menu_position = "Pac";
    ac_ow.accept_multiple_dlocs = false;
    ac_ow.can_queue = true;
    ac_ow.can_execute_without_dloc = false;
    ac_ow.has_button = false;
         
    actions = [ac_mu ac_sh ac_rs ac_tr ac_ps ac_pc ac_pt ac_ow];  
end