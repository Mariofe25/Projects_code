function actions = dataman_glyr_menu()
import xylobium.dledit.Action;
import glyr.processing.action.*

ac_fv = Action("Get FoV", @get_fov, false, true);
ac_fv.menu_position = "RoIs";
ac_fv.accept_multiple_dlocs = true;
ac_fv.can_queue = false;
ac_fv.can_execute_without_dloc = true;
ac_fv.has_button = false;

ac_mt = Action("Tseries to mark", @mark_this, false, true);
ac_mt.menu_position = "RoIs";
ac_mt.accept_multiple_dlocs = true;
ac_mt.can_queue = false;
ac_mt.can_execute_without_dloc = false;
ac_mt.has_button = false;

ac_bc = Action("Plot behaviour-ROIs", @plot_behav_ca, false, true);
ac_bc.menu_position = "RoIs";
ac_bc.accept_multiple_dlocs = false;
ac_bc.can_queue = true;
ac_bc.can_execute_without_dloc = false;
ac_bc.has_button = false;

ac_dff = Action("Extract dff rois", @extract_rois_dff, false, true);
ac_dff.menu_position = "RoIs";
ac_dff.accept_multiple_dlocs = false;
ac_dff.can_queue = true;
ac_dff.can_execute_without_dloc = false;
ac_dff.has_button = false;

ac_ad = Action("Add multiple directories", @add_dirs, false, true, "A");
ac_ad.menu_position = "File";
ac_ad.accept_multiple_dlocs = false;
ac_ad.can_execute_without_dloc = true;

ac_st = Action("Get stabilization template", @template_stab, false, true);
ac_st.menu_position = "Tools";
ac_st.accept_multiple_dlocs = false;
ac_st.can_queue = true;
ac_st.can_execute_without_dloc = false;
ac_st.has_button = false;

ac_mc = Action("Stabilize by template", @stabilize_by_template, false, true);
ac_mc.menu_position = "Tools";
ac_mc.accept_multiple_dlocs = false;
ac_mc.can_queue = true;
ac_mc.can_execute_without_dloc = false;
ac_mc.has_button = false;

actions = [ac_fv ac_mt ac_bc ac_dff ac_ad ac_st ac_mc];
end