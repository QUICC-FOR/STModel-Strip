
#################################
# Define the model
#################################
model = function(t,y,params) {
	with(as.list(c(y,params)), {

		# Fraction of empty patches converted into the different states following a disturbance
		pB = alphab*(B+M)
		pT = alphat*(T+M)
		pM = pB*pT
		pB_ = pB*(1-pT)
		pT_ = pT*(1-pB)

		# Regeneration state
		R = 1 - B - T - M

		# Differential equations describing the dynamics of the state variables
		dBdt = pB_*R + theta*(1-thetat)*M - betat*(T+M)*B - eps*B
		dTdt = pT_*R + theta*thetat*M - betab*(B+M)*T - eps*T
		dMdt = pM*R + betab*(B+M)*T + betat*(T+M)*B - theta*M - eps*M
		list(c(dBdt,dTdt,dMdt))
		})
	}

#################################
# Local stability
#################################
get_eq = function(params) {

	library(rootSolve)
	library(deSolve)

	# Initial conditions
	y = c(B = 0.25, T = 0.25, M = 0.25)

	# Get the equilibrium
	eq0 = ode(y=y, func=model, parms=params,times = seq(0,10,0.1))
	eq = stode(y=eq0[101,2:4], func=model, parms=params, positive = TRUE)

	return(eq$y)
}
#################################
# Wrapper to collect parameters for a given set of environmental conditions
#################################
logit_reverse <- function(x) exp(x)/(1+exp(x))

get_pars = function(ENV1,ENV2,params,int) {

	logit_alphab 	= params["ab0",1] + params["ab1",1]*ENV1 + params["ab2",1]*ENV2 + params["ab3",1]*ENV1^2 + params["ab4",1]*ENV2^2
	logit_alphat 	= params["at0",1] + params["at1",1]*ENV1 + params["at2",1]*ENV2 + params["at3",1]*ENV1^2 + params["at4",1]*ENV2^2
	logit_betab 	= params["bb0",1] + params["bb1",1]*ENV1 + params["bb2",1]*ENV2 + params["bb3",1]*ENV1^2 + params["bb4",1]*ENV2^2
	logit_betat 	= params["bt0",1] + params["bt1",1]*ENV1 + params["bt2",1]*ENV2 + params["bt3",1]*ENV1^2 + params["bt4",1]*ENV2^2
	logit_theta		= params["th0",1] + params["th1",1]*ENV1 + params["th2",1]*ENV2 + params["th3",1]*ENV1^2 + params["th4",1]*ENV2^2
	logit_thetat	= params["tt0",1] + params["tt1",1]*ENV1 + params["tt2",1]*ENV2 + params["tt3",1]*ENV1^2 + params["tt4",1]*ENV2^2
	logit_eps 		= params["e0",1]  + params["e1",1]*ENV1 + params["e2",1]*ENV2  + params["e3",1]*ENV1^2 + params["e4",1]*ENV2^2

	alphab = 1-(1-logit_reverse(logit_alphab))^int
	alphat = 1-(1-logit_reverse(logit_alphat))^int
	betab = 1-(1-logit_reverse(logit_betab))^int
	betat = 1-(1-logit_reverse(logit_betat))^int
	theta = 1-(1-logit_reverse(logit_theta))^int
	thetat = 1-(1-logit_reverse(logit_thetat))^int
	eps = 1-(1-logit_reverse(logit_eps))^int

	return(c(alphab = alphab, alphat = alphat, betab = betab, betat = betat, theta = theta, thetat = thetat, eps = eps))

}

#################################
# SOLVE STM
#################################

solve_stm <- function(clim,pars){

	# Scale the data to match the scaling of the parameters
	T = clim$tp
	PP = clim$pp
  # Loop around all cells
	pSTM = matrix(nr = nrow(clim), nc = 3)
	  for(x in 1:nrow(clim)) {
			print(x)
			if(all(T[x] != -9999 && PP[x] != -9999 && !is.na(T[x]) && !is.na(PP[x]))){
				local_pars = get_pars(T[x],PP[x],pars,int=5)
				pSTM[x,] = get_eq(local_pars)
			} else {
				pSTM[x,] <- rep(NA,3)
			}
	  }

	pSTM <- as.data.frame(pSTM)
  names(pSTM) <- c("B","T","M")

  return(pSTM)
}
