% clear classes
% 
% mod = py.importlib.import_module('synth_matlab');
% py.importlib.reload(mod);

Q_diag = [1, 1];
sigma  = 0.05;

mu_odom = [0.5, 0.1];
mu_obse = [0.2, 0.05];

ekf = py.synth_matlab.Matlab_EKF(Q_diag, sigma, mu_odom, mu_obse);

v  = 0.6;
w  = 0.15;
dt = 0.02;

skipped = 10;
npoints = 300;
xsize = [-4 6];
ysize = [-1 10];

ekf.add_landmark( 1, 2, 3)
ekf.add_landmark( 2, 3, 3)
ekf.add_landmark( 3, 0, 4)
ekf.add_landmark( 4, 2, 4)

landmarks_x = np_matlab(ekf.get_landmarks_x());
landmarks_y = np_matlab(ekf.get_landmarks_y());

robot_path_x = zeros(npoints, 1);
robot_path_y = zeros(npoints, 1);

estim_path_x = zeros(npoints, 1);
estim_path_y = zeros(npoints, 1);

noise_path_x = zeros(npoints, 1);
noise_path_y = zeros(npoints, 1);

figure('units','normalized','outerposition',[0 0 1 1])
for i = 1:npoints * skipped
    w = w + 0.00003;
    
    ekf.update_step()
    ekf.prediction_step(v, w, dt)

    if mod(i, skipped) == 0
        k = i / skipped;
        
        pause(0.001)
        clf

        estimate   = np_matlab(ekf.get_estimate());
        covariance = np_matlab(ekf.get_covariance());

        scatter(landmarks_x, landmarks_y, 'gx')
        hold on
        grid minor
        xlim(xsize)
        ylim(ysize)

        current_robot = np_matlab(ekf.get_robot());
        current_noise = np_matlab(ekf.get_odom());

        robot_path_x(k) = current_robot(1);
        robot_path_y(k) = current_robot(2);
        plot(robot_path_x(1:k), robot_path_y(1:k), 'g.-')
        hold on
        
        noise_path_x(k) = current_noise(1);
        noise_path_y(k) = current_noise(2);
        plot(noise_path_x(1:k), noise_path_y(1:k), 'r.-')
        hold on
        
        estim_path_x(k) = estimate(1);
        estim_path_y(k) = estimate(2);
        plot(estim_path_x(1:k), estim_path_y(1:k), 'blue.-')
        hold on

        try 
            h = error_ellipse(covariance(1:2,1:2), estimate(1:2));
            h.Color = 'Blue';
            plot(h)
            hold on
        catch       
        end
        
        for j = 0:length(landmarks_x) - 1

            x = 4 + j * 2;
            y = 5 + j * 2;
            scatter(estimate(x),estimate(y), 'rx')
            hold on
            try 
                h = error_ellipse(covariance(x:y,x:y), estimate(x:y));
                h.Color = 'Red';
                plot(h)
                hold on
            catch
            end
        end
    end
end


