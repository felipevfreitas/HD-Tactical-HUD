// ------------------------------------------------------------
// Tactical HUD v1.1.0 - mag check: lower and raise the weapon
//
// When the inspect key is pressed, the weapon drops down like when
// switching weapons, stays down for a moment, then comes back up.
//
// Purely visual: only the weapon layer's vertical position is changed,
// on top of what HD itself set this tic (so its bob/sway is kept).
// The weapon is never actually deselected, so it can't change any state.
// The thinker runs in STAT_DEFAULT, which ticks after the players.
// ------------------------------------------------------------
class HDRNHandler:EventHandler{
	override void NetworkProcess(ConsoleEvent e){
		if(e.Name!="hdrn_magcheck")return;
		int pn=e.Player;
		if(pn<0||pn>=MAXPLAYERS||!playeringame[pn])return;
		let cv=CVar.GetCVar("hdrn_inspectanim",players[pn]);
		if(cv&&!cv.GetBool())return;
		double spd=1.;
		let cs=CVar.GetCVar("hdrn_inspectanimspeed",players[pn]);
		if(cs)spd=clamp(cs.GetFloat(),0.5,4.);
		//how far down the weapon goes: 0% = doesn't move, 100% = off screen
		double drop=30.;
		let cd=CVar.GetCVar("hdrn_inspectdrop",players[pn]);
		if(cd)drop=clamp(cd.GetFloat(),0.,100.);
		if(drop<=0.)return;
		HDRNMagCheckSim.Start(pn,spd,drop*0.01);
	}
}

class HDRNMagCheckSim:Thinker{
	//timings at 1x speed
	const RN_DOWNTICS=10;
	const RN_HOLDTICS=8;
	const RN_UPTICS=10;
	const RN_DROP=WEAPONBOTTOM-WEAPONTOP;	//same distance as a weapon switch

	int pnum;
	weapon wep;
	int downtics,holdtics,uptics;
	int elapsed;
	double dropfrac;
	double basey;
	double lastwritten;
	bool haswritten;

	static bool IsMenuWeapon(hdweapon hdw){
		return
			hdw.balwaysshowstatus
			||hdw is "HDStorageItem"
			||hdw is "MagManager"
			||hdw is "PickupManager"
			||hdw is "DERPUsable"
			||hdw is "HERPUsable"
		;
	}

	static void Start(int pn,double spd,double dropfrac){
		let p=players[pn];
		let mo=p.mo;
		if(!mo||mo.health<1)return;
		let hdw=hdweapon(p.readyweapon);
		if(
			!hdw
			||hdw.bweaponbusy
			||p.pendingweapon!=WP_NOCHANGE
			||IsMenuWeapon(hdw)
			||!p.FindPSprite(PSP_WEAPON)
		)return;

		//only one at a time per player
		let it=ThinkerIterator.Create("HDRNMagCheckSim",STAT_DEFAULT);
		HDRNMagCheckSim old;
		while(old=HDRNMagCheckSim(it.Next())){
			if(old.pnum==pn)old.Destroy();
		}

		let sim=new("HDRNMagCheckSim");
		sim.pnum=pn;
		sim.wep=hdw;
		sim.dropfrac=dropfrac;
		sim.downtics=max(1,int(RN_DOWNTICS/spd+0.5));
		sim.holdtics=max(0,int(RN_HOLDTICS/spd+0.5));
		sim.uptics=max(1,int(RN_UPTICS/spd+0.5));
		mo.A_StartSound("weapons/pocket",CHAN_AUTO,CHANF_OVERLAP,0.4);
	}

	static double Smooth(double x){
		x=clamp(x,0.,1.);
		return x*x*(3.-2.*x);
	}

	override void Tick(){
		if(!playeringame[pnum]){
			Destroy();
			return;
		}
		let p=players[pnum];
		let mo=p.mo;
		let psp=p.FindPSprite(PSP_WEAPON);

		//stop as soon as the player does anything with the weapon
		if(
			!mo
			||mo.health<1
			||!psp
			||p.readyweapon!=wep
			||p.pendingweapon!=WP_NOCHANGE
			||(hdweapon(wep)&&hdweapon(wep).bweaponbusy)
			||p.cmd.buttons&(
				BT_ATTACK|BT_ALTATTACK|BT_RELOAD|BT_ZOOM
				|BT_USER1|BT_USER2|BT_USER3|BT_USER4
			)
		){
			Destroy();
			return;
		}

		elapsed++;
		double dip;
		if(elapsed<=downtics){
			dip=Smooth(elapsed/double(downtics));
		}else if(elapsed<=downtics+holdtics){
			dip=1.;
		}else{
			int u=elapsed-downtics-holdtics;
			if(u>=uptics){
				Destroy();
				return;
			}
			dip=1.-Smooth(u/double(uptics));
		}
		//HD normally re-places the weapon every tic; if it did, start from
		//its new position (keeps the bob), otherwise reuse the last one
		if(!haswritten||abs(psp.y-lastwritten)>0.001)basey=psp.y;
		psp.y=basey+dip*RN_DROP*dropfrac;
		lastwritten=psp.y;
		haswritten=true;
	}
}
