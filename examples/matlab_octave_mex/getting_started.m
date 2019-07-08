clear all
close all
clc



fprintf('\nHPIPM matlab interface: getting started example\n');



% check that env.sh has been run
env_run = getenv('ENV_RUN');
if (~strcmp(env_run, 'true'))
	disp('ERROR: env.sh has not been sourced! Before executing this example, run:');
	disp('source env.sh');
	return;
end



% define flags
codegen_data = 1; % export qp data in the file qp_data.c for use from C examples
constr_type = 0; % 0 box, 1 general



%%% data %%%
N = 5;
nx = 2;
nu = 1;

A = [1, 1; 0, 1];
B = [0; 1];
%b = [0; 0]

Q = [1, 0; 0, 1];
S = [0, 0];
R = [1];
q = [1; 1];
%r = [0];

Jx = [1, 0; 0, 1];
x0 = [1; 1];



%%% dim %%%
dim = hpipm_ocp_qp_dim(N);

dim.set('nx', nx, 0, N);
dim.set('nu', nu, 0, N-1);
if(constr_type==0)
	dim.set('nbx', nx, 0);
	dim.set('nbx', nx, 5);
else
	dim.set('ng', nx, 0);
	dim.set('ng', nx, 5);
end

% print to shell
%dim.print_C_struct();
% codegen
if codegen_data
	dim.codegen('qp_data.c', 'w');
end



%%% qp %%%
qp = hpipm_ocp_qp(dim);

qp.set('A', A, 0, N-1);
qp.set('B', B, 0, N-1);
qp.set('Q', Q, 0, N);
qp.set('S', S, 0, N-1);
qp.set('R', R, 0, N-1);
qp.set('q', q, 0, N);
%qp.set('r', r, 0, N-1);
if(constr_type==0)
	qp.set('Jbx', Jx, 0);
	qp.set('lbx', x0, 0);
	qp.set('ubx', x0, 0);
	qp.set('Jbx', Jx, N);
else
	qp.set('C', Jx, 0);
	qp.set('lg', x0, 0);
	qp.set('ug', x0, 0);
	qp.set('C', Jx, N);
end

% print to shell
%qp.print_C_struct();
% codegen
if codegen_data
	qp.codegen('qp_data.c', 'a');
end



%%% sol %%%
sol = hpipm_ocp_qp_sol(dim);



%%% solver arg %%%
%mode = 'speed_abs';
mode = 'speed';
%mode = 'balance';
%mode = 'robust';
% create and set default arg based on mode
arg = hpipm_ocp_qp_solver_arg(dim, mode);

% overwrite default argument values
arg.set('mu0', 1e4);
arg.set('iter_max', 20);
arg.set('tol_stat', 1e-4);
arg.set('tol_eq', 1e-5);
arg.set('tol_ineq', 1e-5);
arg.set('tol_comp', 1e-5);
arg.set('reg_prim', 1e-12);

% codegen
if codegen_data
	arg.codegen('qp_data.c', 'a');
end



%%% solver %%%
solver = hpipm_ocp_qp_solver(dim, arg);

% arg which are allowed to be changed
solver.set('iter_max', 30);
arg.set('tol_stat', 1e-8);
arg.set('tol_eq', 1e-8);
arg.set('tol_ineq', 1e-8);
arg.set('tol_comp', 1e-8);

% solve qp
nrep = 100;
tic
for rep=1:nrep
	solver.solve(qp, sol);
end
solve_time = toc;

% get solution statistics
fprintf('\nprint solver statistics\n');
status = solver.get('status')
fprintf('average solve time over %d runs: %e [s]\n', nrep, solve_time/nrep);
iter = solver.get('iter')
res_stat = solver.get('res_stat')
res_eq = solver.get('res_eq')
res_ineq = solver.get('res_ineq')
res_comp = solver.get('res_comp')
stat = solver.get('stat');
fprintf('iter\talpha_aff\tmu_aff\t\tsigma\t\talpha\t\tmu\t\tres_stat\tres_eq\t\tres_ineq\tres_comp\n');
for ii=1:iter+1
	fprintf('%d\t%e\t%e\t%e\t%e\t%e\t%e\t%e\t%e\t%e\n', stat(ii,1), stat(ii,2), stat(ii,3), stat(ii,4), stat(ii,5), stat(ii,6), stat(ii,7), stat(ii,8), stat(ii,9), stat(ii,10));
end



% get / print solution
% x
x = sol.get('x', 0, N);
x = reshape(x, nx, N+1);
% u
u = sol.get('u', 0, N-1);
u = reshape(u, nu, N);

x
u

% print to shell
%sol.print_C_struct();



if status==0
	fprintf('\nsuccess!\n\n');
else
	fprintf('\nsolution failed!\n\n');
end



if is_octave()
	% directly call destructor for octave 4.2.2 (ubuntu 18.04) + others ???
	if strcmp(version(), '4.2.2')
		delete(dim);
		delete(qp);
		delete(sol);
		delete(arg);
		delete(solver);
	end
end



waitforbuttonpress;



return

