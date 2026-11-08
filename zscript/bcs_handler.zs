// ------------------------------------------------------------
// Lado do jogo do Boss Scope Centralizado:
//  - sensibilidade normalizada no scope
//  - zoom fora do scope (0-100% do zoom do scope)
//  contas de zoom em bcs_math.zs
//
// O HD define Weapon.LookScale e player.fov a cada tic dentro de
// HDPlayerPawn.MovePlayer (P_PlayerThink), que roda antes dos
// thinkers e do WorldTick. Aqui sobrescrevemos os dois depois
// disso, so enquanto o scope esta em uso. O FOV base vem sempre de
// desiredfov*recoilfov, nunca do fov ja alterado, para nao acumular.
// ------------------------------------------------------------

class BossScopeHandler:EventHandler{
	//aumento atual fora do scope (1 = sem zoom), por jogador
	double zoomcur[MAXPLAYERS];

	//quanto do zoom do scope vai para fora (0.8 = 80%)
	const OUTZOOM_AMOUNT=0.8;

	static int GetUserInt(PlayerInfo p,string name,int def){
		cvar cv=cvar.getcvar(name,p);
		return cv?cv.getint():def;
	}
	static double GetUserFloat(PlayerInfo p,string name,double def){
		cvar cv=cvar.getcvar(name,p);
		return cv?cv.getfloat():def;
	}

	override void WorldTick(){
		for(int i=0;i<MAXPLAYERS;i++){
			if(!playeringame[i])continue;
			PlayerInfo p=players[i];
			if(zoomcur[i]<=0.)zoomcur[i]=1.;

			let hpl=hdplayerpawn(p.mo);
			if(!hpl){
				zoomcur[i]=1.;
				continue;
			}
			//whole scope addon switched off: leave HD's fov/sensitivity alone
			if(!GetUserInt(p,"bcs_modon",1)){
				zoomcur[i]=1.;
				continue;
			}
			double basefov=p.desiredfov*(hpl.recoilfov>0?hpl.recoilfov:1.);

			//o scope esta em uso? mesma regra do HD para mostrar o scope,
			//mas so com Zoom pressionado (no modo passivo 0 o scope fica
			//sempre na tela e nada voltaria ao normal)
			let wp=hdweapon(p.readyweapon);
			int scopeid=BCSScopes.Identify(wp);
			int nscp=GetUserInt(p,"hd_noscope",0);
			bool centered=GetUserInt(p,"bcs_enabled",1)!=0;
			bool active=
				hpl.health>0
				&&hpl.scopecamera
				&&wp
				&&scopeid!=BCSScopes.SC_NONE
				&&BCSScopes.HasScopeNow(wp,scopeid)
				&&(p.cmd.buttons&BT_ZOOM)
				&&nscp>=0
				&&nscp<=2
			;

			double scopefov=1.,narrowestfov=1.;
			if(active)[scopefov,narrowestfov]=BCSScopes.ScopeFOV(wp,scopeid);
			double size=1.;
			if(centered)size=clamp(GetUserFloat(p,"bcs_size",1.6),0.5,6.0);
			double cal=1.;	//sem calibracao


			// --- zoom fora do scope ---
			//so com o scope centralizado: o desenho original do HD
			//muda de tamanho com o FOV e some abaixo de 13 graus
			double target=1.;
			//zoom de fora fixo em 80% do zoom do scope (liga/desliga no menu)
			double t=GetUserInt(p,"bcs_outzoomon",1)?OUTZOOM_AMOUNT:0.;
			if(active&&centered&&t>0.){
				double scopemag=BCSMath.ScopeMag(basefov,scopefov,size,cal);
				double narrowmag=BCSMath.ScopeMag(
					basefov,min(scopefov,narrowestfov),size,cal
				);
				target=BCSMath.OutsideMag(
					basefov,scopemag,narrowmag,t,
					0	//escala relativa
				);
			}

			if(GetUserInt(p,"bcs_outzoomsmooth",0)){
				//suave: chega no alvo em uns 4 tics
				zoomcur[i]+=(target-zoomcur[i])*0.5;
				if(abs(target-zoomcur[i])<0.0005)zoomcur[i]=target;
			}else{
				//instantaneo, como o zoom do scope
				zoomcur[i]=target;
			}

			if(zoomcur[i]!=1.){
				p.fov=BCSMath.FOVFromMag(basefov,zoomcur[i]);
			}


			// --- sensibilidade ---
			if(!active)continue;
			int mode=GetUserInt(p,"bcs_sensmode",0);
			if(mode<1)continue;

			//igual na tela (unico modo; qualquer valor acima de 0 usa este):
			//um movimento do mouse anda a mesma distancia na tela dentro
			//do scope e na visao normal, ou seja, 1/aumento visto no scope.
			//no scope original do HD o hd_crosshairscale ainda conta
			double k=size;
			if(!centered){
				k=clamp(GetUserFloat(p,"hd_crosshairscale",1.),0.1,3.0)
					*BCSScopes.OriginalCamWidth(scopeid)/90.;
			}
			double scale=1./max(0.001,BCSMath.ScopeMag(basefov,scopefov,k,cal));

			scale*=clamp(GetUserFloat(p,"bcs_sensmult",1.),0.1,5.0);

			//mantem a penalidade de atordoamento do HD
			if(hpl.stunned)scale*=0.3;

			wp.lookscale=clamp(scale,0.001,1.0);
		}
	}
}
