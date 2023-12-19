function plot_locomotion(trial,do_cats)
figure
if do_cats
    % use categorize_locomotion_old
    loc = trial.load_var('Categorize_locomotion');
    plot(loc,'LineWidth',1)
    hold on
    for i = 3:width(loc)
        plot(loc.Time,loc(:,i).Variables)
    end
else
    bin = trial.load_var('running');
    loc = trial.load_var('locomotion_classification');
    plot(bin.Time,bin.Data,'LineWidth',2)
    hold on
    for i = 1:width(loc)
        if contains(loc.Properties.VariableNames{i},{'1','2'})
            plot(bin.Time,loc(:,i).Variables,'LineStyle','--')
        else
            plot(bin.Time,loc(:,i).Variables)
        end
    end
    legend(["Locomotion",loc.Properties.VariableNames])
    ylim([0 1.5])
    grid on   
end
grid on
hold off
end


%stackedplot(loc)