%{
Overlay to hold the roi polygon paint tool's controls.
%}
classdef BrukerShotspot< roiman.ViewModule
    properties
        ax
    end
    methods
        function obj = BrukerShotspot(name)
            obj@roiman.ViewModule(name, "shotspot")
        end
        function on_init(obj, manager, view)
            [~, v_write,~] = view.data.shorts();
            [~, m_write, m_read] = view.manager.data.shorts();
            dims = m_read("dimensions");
            obj.ax = view.request_ax(dims(1), dims(2), true);
            %             [w,h] = obj.get_wh(manager);
            %             obj.ax = view.request_ax(w, h, true);
            tseries = m_read("tseries");
            
            % grab shotspot from tseries 
            shot_spot =  Pac.get_shotspot(tseries);
            % draw shotspot in ax
            plot(obj.ax,shot_spot.x,shot_spot.y,'Marker','.','Color','r','MarkerSize',35)
            drawnow
        end
        function on_enable(obj, manager, view)
        end
        function on_disable(obj, manager, view)
        end
        function on_update(obj, manager, view)
        end
    end
end