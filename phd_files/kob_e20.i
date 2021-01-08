
[GlobalParams]
enable_jit = false
displacements = 'disp_x disp_y'
[]

[Mesh]
	type = GeneratedMesh
	dim = 2
	xmax = 3
	ymax = 3
	nx = 100
	ny = 100
[]

[Variables]
	[./phi]
		#scaling = 10
	[../]
	[./T]
		#scaling = 1e-3
	[../]
       [./disp_x]
		order = FIRST
		family = LAGRANGE
		#scaling = 1e4
	[../]
	[./disp_y]
		order = FIRST
		family = LAGRANGE
		#scaling = 1e4
	[../]

[]

[ICs]
	[./phi_ic]
		type = SmoothCircleFromFileIC
		file_name = 'circles.txt'
		invalue = 1
		outvalue = 0
		variable = phi
		int_width =0.1 
	[../]

[]

[Functions]
	[./hf]
		type = PiecewiseLinear
		x = '0     0.047     0.089    0.13    0.17    0.213      0.28     0.32      0.38      0.46     0.53      0.6      0.72     0.84     0.98      1'
		y = '7e7   7.47e7   7.89e7   8.3e7   8.72e7   9.13e7    9.82e7   1.022e8    1.077e8  1.16e8    1.23e8   1.3e8    1.42e8   1.54e8    1.68e8   1.78e8'                                    

	[../]
[]


[Modules/TensorMechanics/Master]
  [./all]
    add_variables = true
    strain = FINITE
    eigenstrain_names = 'thermal_expansion   vol_strain'
    generate_output = 'stress_xx  stress_yy  strain_xx  strain_yy  stress_xy  stress_yx  plastic_strain_xx  plastic_strain_yy  plastic_strain_xy  plastic_strain_yx  vonmises_stress'
  [../]
[]

[Kernels]
	[./phi_dot]
		type = TimeDerivative
		variable = phi
	[../]
	[./AC_Interface1]
		type = ACInterfaceKobayashi1
		variable = phi
		mob_name = M
		
	[../]
	[./AC_interface2]
		type = ACInterfaceKobayashi2
		variable = phi
		mob_name = M
	[../]
	[./Allen_Cahn]
		type = AllenCahn
		variable = phi
		mob_name = M
		f_name = F
		args = T
	[../]
	[./langevin]
    		type = LangevinNoise
    		amplitude = 0.01
    		variable = phi
		#noise = normal_noise
  	[../]


	[./T_dot]
		type = TimeDerivative
		variable = T
	[../]
	[./T_diffusion]
		type = MatDiffusion
		variable = T
		D_name = D
	[../]
	[./T_coupling]
		type = CoefCoupledTimeDerivative
    		variable = T
    		v = phi
    		coef = -1.2
	[../]
	
	[./pls_strain]
		type = PlasticHeatEnergy
		variable = T
		displacements = 'disp_x  disp_y'
		coeff = 15e-20
	 [../]
[]	

[Materials]
	[./free_energy]
		type = DerivativeParsedMaterial
		f_name = fbulk
		args = 'T phi'
		constant_names = '     Tm     gamma  alpha   pi'
		constant_expressions = ' 1     10    0.9   3.14'  
		function = 'm:=(alpha/pi)*atan((gamma*(Tm-T)));
                          0.25*phi^4 - (0.5-(0.33*m))*phi^3 + (0.25-(0.5*m))*phi^2' 
		derivative_order = 2
		outputs=exodus
	[../]
	[./stiffness]
		type = ComputeIsotropicElasticityTensor
		youngs_modulus = 110e9
		poissons_ratio = 0.31
	[../]
	
	[./thermal_expansion]
		type = ComputeThermalExpansionEigenstrain
		thermal_expansion_coeff = 17e-6
		stress_free_temperature = 0
		temperature = T
		eigenstrain_name = thermal_expansion
		outputs = exodus
	[../]
	[./vol_strain]
		type = ComputeEigenstrain
		eigenstrain_name = vol_strain
		eigen_base = '4e-2  4e-2  0  0  0  0'
		prefactor = prefactor
		
	[../]
	[./prefactor]
		type = ParsedMaterial
		f_name = prefactor
		args = 'T phi'
		constant_names = '     Tm     gamma  alpha   pi'
		constant_expressions = ' 1     10    0.9   3.14'  
		function = 'm:=(alpha/pi)*atan((gamma*(Tm-T)));
                          phi*(phi^3 - (1.5-m)*phi^2 + (0.5-m)*phi)' 
		derivative_order = 2
		
	[../]	
	
	[./isoplas]
 		 type = IsotropicPlasticityStressUpdate
  		 yield_stress = 7e7
  		 hardening_function = hf
	[../]

	[./radial_return_stress]
		type = ComputeMultipleInelasticStress
		tangent_operator = nonlinear
		inelastic_models = 'isoplas'
	[../]

	[./elastic_energy]
		type = ElasticEnergyMaterial
		f_name = f_elastic
		args = 'phi'
		outputs = exodus
	[../]
	
	[./phe]
		type = ComputePlasticHeatEnergy
		outputs = exodus
	[../]
	
	
#Global free energy
  [./switching]
    type = SwitchingFunctionMaterial
    block = 0
    eta = phi
    h_order = SIMPLE
  [../]
  [./barrier]
    type = BarrierFunctionMaterial
    block = 0
    eta = phi
    g_order = SIMPLE
  [../]
  [./sum_energy]
    type = DerivativeSumMaterial
    block = 0
    f_name = F
    sum_materials = 'fbulk f_elastic'
    args = 'T phi'
    derivative_order = 2
  [../]

  [./material]
    		type = InterfaceOrientationMaterial
    		eps_bar = 0.01
    		mode_number = 4
    		anisotropy_strength = 0.05
    		op = phi
		reference_angle = 0
  [../]

  [./Constants]
		type = GenericConstantMaterial
       	prop_names  = 'D  M'
    		prop_values = '1  3333.33 '
  [../]
[]


[./BCs]
	[./temp]
		type = CoupledConvectiveFlux
		variable = 'T'
		boundary = 'left top right bottom'
		T_infinity = 0.5
		coefficient = 200
	[../]
		
	[./bottom_X]
		type = DirichletBC
		variable = disp_x
		value = 0
		boundary = bottom
	[../]
	[./bottom_Y]
		type = DirichletBC
		variable = disp_y
		value = 0
		boundary = bottom
	[../]
	[./left_X]
		type = DirichletBC
		variable = disp_x
		value = 0
		boundary = left
	[../]
	[./left_Y]
		type = DirichletBC
		variable = disp_y
		value = 0
		boundary = left
	[../]
	[./top_X]
		type = DirichletBC
		variable = disp_x
		value = 0
		boundary = top
	[../]
	[./top_Y]
		type = DirichletBC
		variable = disp_y
		value = 0
		boundary = top
	[../]
	[./right_X]
		type = DirichletBC
		variable = disp_x
		value = 0
		boundary = right
	[../]
	[./right_Y]
		type = DirichletBC
		variable = disp_y
		value = 0
		boundary = right
	[../]
[]

[Preconditioning]
  	[./SMP]
	   	type = SMP
	   	full = true
  	[../]

[]

[Executioner]
  type = Transient
  scheme = bdf2
  solve_type = PJFNK

  #petsc_options = '-pc_svd_monitor'
  #petsc_options_iname ='-pc_type'
  #petsc_options_value = 'svd'


  petsc_options = '-snes_converged_reason -snes_error_if_not_converged -ksp_converged_reason -ksp_error_if_not_converged -snes_view'
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre    boomeramg          101'

  l_max_its = 30
  nl_abs_tol = 1e-10
  nl_rel_tol = 1e-08
  end_time = 200.0
  dt = 2e-4
  automatic_scaling = true
  compute_scaling_once = false

  #[./Adaptivity]
  #  initial_adaptivity = 0 # Number of times mesh is adapted to initial condition
  #  refine_fraction = 0.7 # Fraction of high error that will be refined
  #  coarsen_fraction = 0.1 # Fraction of low error that will coarsened
  #  max_h_level = 2 # Max number of refinements used, starting from initial mesh (before uniform refinement)
  #  weight_names = 'phi T'
  #  weight_values = '1 0.5'
  #[../]

#[./TimeStepper]
#    type = IterationAdaptiveDT
#    optimal_iterations = 6
#    iteration_window = 2
#    dt = 2e-4
#    growth_factor = 1.1
#    cutback_factor = 0.75
#  [../]


	
[]
[Outputs]
  interval = 10
  exodus = true
  print_perf_log = true
[]

[Debug]
	show_actions = true
	show_material_props = true
	show_top_residuals = 1
	show_var_residual_norms = true
[]
