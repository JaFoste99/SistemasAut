clear classes

addpath('MATLAB_code')

pymod_ekf = py.importlib.import_module('ekf_unknown');
pymod_models = py.importlib.import_module('synth_base');
pymod_matlab = py.importlib.import_module('synth_matlab_unknown');

py.importlib.reload(pymod_ekf);
py.importlib.reload(pymod_models);
py.importlib.reload(pymod_matlab);

% Par�metros do ekf
Q_diag = [4, 4];
sigma  = 0.05;

% Vari�ncias dos sensores
mu_odom = [0.01, 0.5];
mu_obse = [0.05, 0.05];

% Novos landmarks
L = 10;
alpha = 0.02;
cov_scaling = 1;

ekf = py.synth_matlab_unknown.Matlab_EKF(Q_diag, sigma, mu_odom, mu_obse, L, alpha);

% Valores m�ximos observa��o
max_angle    = pi / 3;
max_distance = 1000;

% Controlos a dar ao robot
v  = 0.9;
w  = 0.1;
dt = 0.01;

% Mudan�a nos controlos a cada periodo
w_var = 0.0001;
v_var = 0;

% Numero de ponto para a anima��o e quantos ciclos de ekf s�o skipped entre
% frames
skipped = 10;
npoints = 400;
xsize = [-4 20];
ysize = [-5 15];


% Inserir landmarks no simulador
ekf.add_landmark( 1, 5, 7)
ekf.add_landmark( 3,-2, 10)
ekf.add_landmark( 4, 5, 12)
ekf.add_landmark( 5,-2, 1)
ekf.add_landmark( 6, 10, 2)
ekf.add_landmark( 7, 15, 3)
ekf.add_landmark( 7, 12, 8)


% N�o deve ser preciso mexer daqui para baixo
landmarks_x = np_matlab(ekf.get_landmarks_x());
landmarks_y = np_matlab(ekf.get_landmarks_y());

robot_path_x = zeros(npoints, 1);
robot_path_y = zeros(npoints, 1);

estim_path_x = zeros(npoints, 1);
estim_path_y = zeros(npoints, 1);

noise_path_x = zeros(npoints, 1);
noise_path_y = zeros(npoints, 1);

fig = figure('units','normalized','outerposition',[0 0 1 1]);
set(fig,'defaultLegendAutoUpdate','off')
hold on
grid minor
xlim(xsize)
ylim(ysize)

h = zeros(3, 1);
h(1) = plot(NaN, NaN, 'g.-');
h(2) = plot(NaN, NaN, 'b.-');
h(3) = scatter(NaN, NaN, 'ob');
h(4) = plot(NaN, NaN, 'r.-');
h(5) = scatter(NaN, NaN, 'xg');
h(6) = scatter(NaN, NaN, 'xr');
h(7) = scatter(NaN, NaN, 'or');
legend(h, 'Robot','Estimate', 'Estimate Covariance' ,'Odom', ...
    'Landmark', 'Landmark Estimation', 'Landmark Covariance', ...
    'Location', 'Northeast');

title('EKF Simulation')
xlabel('x [m]')
ylabel('y [m]')

for i = 1:npoints * skipped
    w = w + w_var;
    v = v + v_var;
    
    ekf.update_step(max_angle, max_distance)
    ekf.prediction_step(v, w, dt)

    if mod(i, skipped) == 0
        k = i / skipped;
        
        pause(0.0001)
        cla

        estimate   = np_matlab(ekf.get_estimate());
        covariance = np_matlab(ekf.get_covariance());

        scatter(landmarks_x, landmarks_y, 'gx')

        current_robot = np_matlab(ekf.get_robot());
        current_noise = np_matlab(ekf.get_odom());

        noise_path_x(k) = current_noise(1);
        noise_path_y(k) = current_noise(2);
        plot(noise_path_x(1:k), noise_path_y(1:k), 'r.-')
        
        robot_path_x(k) = current_robot(1);
        robot_path_y(k) = current_robot(2);
        plot(robot_path_x(1:k), robot_path_y(1:k), 'g.-')
        
        estim_path_x(k) = estimate(1);
        estim_path_y(k) = estimate(2);
        plot(estim_path_x(1:k), estim_path_y(1:k), 'blue.-')

        try 
            h = error_ellipse(covariance(1:2,1:2)/cov_scaling, estimate(1:2));
            h.Color = 'Blue';
            plot(h)
        catch
        end
        
        for j = 0: (length(covariance) - 3) / 2 - 1

            x = 4 + j * 2;
            y = 5 + j * 2;
            scatter(estimate(x),estimate(y), 'rx')
            try 
                h = error_ellipse(covariance(x:y,x:y)/cov_scaling, estimate(x:y));
                h.Color = 'Red';
                plot(h)
            catch
            end
        end
    end
end


