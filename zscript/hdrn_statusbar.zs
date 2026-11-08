// ------------------------------------------------------------
// Tactical HUD v1.0.0 - "Ready or Not" style HUD for Hideous Destructor
//
// - Paper doll (bottom left) filled from the bottom up according
//   to health, tinted white -> yellow -> orange -> red.
//   Lost maximum health grows from the top down in dark red with
//   darker diagonal stripes.
// - ECG / heart rate next to the paper doll.
// - Weapon readout moved to the bottom right.
// - "Inspect ammo" key shows the equipped weapon's magazines at the
//   bottom centre, each one filled according to its round count.
// - Inventory / items in the top right (can be disabled).
// ------------------------------------------------------------
class HDRNStatusBar:HDStatusBar{

	//cached cvars
	transient cvar rn_enable;
	transient cvar rn_inspectreq;
	transient cvar rn_inspecthold;
	transient cvar rn_showonpump;
	transient cvar rn_alwaysweapon;
	transient cvar rn_ammocolor;
	transient cvar rn_ammousepcol;
	transient cvar rn_compass;
	transient cvar rn_compasswhen;
	transient cvar rn_compasselastic;
	transient cvar rn_compasszoom;
	transient cvar rn_inspecttime;
	transient cvar rn_inspectonreload;
	transient cvar rn_magnumbers;
	transient cvar rn_magscale;
	transient cvar rn_dollscale;
	transient cvar rn_showecg;
	transient cvar rn_showhpnum;
	transient cvar rn_inventory;
	transient cvar rn_showitems;
	transient cvar rn_weaponname;
	transient cvar rn_firemodeshow;
	transient cvar rn_armourstyle;
	transient cvar rn_armournum;
	transient cvar rn_armourwidth;
	transient cvar rn_safex;
	transient cvar rn_safey;
	transient cvar rn_safeaspect;

	enum HDRNConsts{
		RN_ECGN=64,			//samples kept for the ECG trace (1 per tic)
		RN_FADETICS=10,		//fade out time of the inspect panel
		RN_QUICKTICS=30,	//quick weapon-only look (after pumping)
		RN_INVSHOWTICS=105,	//"auto" inventory: how long it stays after a change
		RN_DMGFLASHTICS=12,
		RN_WAVELEN=16,
		RN_FLAGS_BL=DI_SCREEN_LEFT_BOTTOM|DI_ITEM_LEFT_TOP,
	}

	//state
	int inspecttimer;
	bool rn_lastreload;
	double rn_disphealth;
	double rn_displost;
	int rn_lasthealth;
	int rn_dmgflash;
	int rn_lastbeat;
	int rn_wavepos;
	double rn_waveamp;
	double rn_ecg[RN_ECGN];
	int rn_ecghead;
	double rn_bpm;
	int rn_seed;
	int rn_invtimer;
	inventory rn_lastinvsel;
	class<HDPickup> rn_inspectammo;
	hdweapon rn_inspectwep;
	double rn_glitchfrac;
	int rn_glitchnum;
	int rn_modeflash;
	double rn_angprev;
	double rn_angcur;
	bool rn_anginit;
	double rn_cmpvel;
	double rn_ticfrac;
	int rn_reloadwatch;
	int rn_pumpwatch;
	hdweapon rn_pumpwatchwep;
	bool rn_lastpump;
	bool rn_inspectweaponly;
	hdweapon rn_reloadwatchwep;
	string rn_lastmode;
	weapon rn_lastmodewep;
	double rn_disparmour;

	//one heart beat, sampled once per tic (P wave, QRS complex, T wave)
	static const double RN_WAVE[]={
		0.10,0.18,0.10,0.,
		-0.12,1.,-0.45,-0.1,
		0.,0.06,0.14,0.22,0.24,0.18,0.08,0.
	};

	static const string RN_KEYITEMS[]={"BlueCard","YellowCard","RedCard","BlueSkull","YellowSkull","RedSkull"};
	static const string RN_KEYGFX[]={"STKEYS0","STKEYS1","STKEYS2","STKEYS3","STKEYS4","STKEYS5"};
	static const string RN_COMPNAMES[]={"$EAST","$SOUTH","$WEST","$NORTH"};
	static const int RN_COMPCOLS[]={Font.CR_GOLD,Font.CR_BLACK,Font.CR_RED,Font.CR_WHITE};
	static const int RN_COMPANGS[]={0,-90,180,90};

	void RN_CacheCvars(){
		if(rn_enable)return;
		rn_enable=CVar.FindCVar("hdrn_enable");
		rn_inspectreq=CVar.FindCVar("hdrn_inspectreq");
		rn_inspecthold=CVar.FindCVar("hdrn_inspecthold");
		rn_showonpump=CVar.FindCVar("hdrn_showonpump");
		rn_alwaysweapon=CVar.FindCVar("hdrn_alwaysweapon");
		rn_ammocolor=CVar.FindCVar("hdrn_ammocolor");
		rn_ammousepcol=CVar.FindCVar("hdrn_ammousepcol");
		rn_compass=CVar.FindCVar("hdrn_compass");
		rn_compasswhen=CVar.FindCVar("hdrn_compasswhen");
		rn_compasselastic=CVar.FindCVar("hdrn_compasselastic");
		rn_compasszoom=CVar.FindCVar("hdrn_compasszoom");
		rn_inspecttime=CVar.FindCVar("hdrn_inspecttime");
		rn_inspectonreload=CVar.FindCVar("hdrn_inspectonreload");
		rn_magnumbers=CVar.FindCVar("hdrn_magnumbers");
		rn_magscale=CVar.FindCVar("hdrn_magscale");
		rn_dollscale=CVar.FindCVar("hdrn_dollscale");
		rn_showecg=CVar.FindCVar("hdrn_showecg");
		rn_showhpnum=CVar.FindCVar("hdrn_showhpnumber");
		rn_inventory=CVar.FindCVar("hdrn_inventory");
		rn_showitems=CVar.FindCVar("hdrn_showitems");
		rn_weaponname=CVar.FindCVar("hdrn_weaponnamemode");
		rn_firemodeshow=CVar.FindCVar("hdrn_firemodemode");
		rn_armourstyle=CVar.FindCVar("hdrn_armourstyle");
		rn_armournum=CVar.FindCVar("hdrn_armournumber");
		rn_armourwidth=CVar.FindCVar("hdrn_armourwidth");
		rn_safex=CVar.FindCVar("hdrn_safex");
		rn_safey=CVar.FindCVar("hdrn_safey");
		rn_safeaspect=CVar.FindCVar("hdrn_safeaspect");
	}
	bool RN_Enabled(){
		return !rn_enable||rn_enable.GetBool();
	}

	//ui-side pseudo random numbers, so the HUD never touches the game's RNG
	double RN_Rand(){
		rn_seed=rn_seed*1103515245+12345;
		return ((rn_seed>>8)&0xffff)/65535.;
	}


	//current state of the weapon layer (read through the psprite list,
	//which is readable from the HUD)
	state RN_WeaponState(){
		for(let p=cplayer.psprites;p;p=p.Next){
			if(p.ID==PSP_WEAPON)return p.curstate;
		}
		return null;
	}
	//is the weapon just idling (ready, or bouncing off a refused action)?
	bool RN_WeaponIdle(weapon w,state cs){
		state r=w.FindState("Ready");
		state re=w.FindState("ReadyEnd");
		state np=w.FindState("Nope");
		return
			(r&&Actor.InStateSequence(cs,r))
			||(re&&Actor.InStateSequence(cs,re))
			||(np&&Actor.InStateSequence(cs,np))
		;
	}

	//short, weapon-only look (no spare ammo); doesn't cut a full panel short
	void RN_StartQuickInspect(int len){
		if(inspecttimer>RN_FADETICS&&!rn_inspectweaponly)return;
		inspecttimer=max(inspecttimer,len);
		rn_inspectweaponly=true;
		let w=hdweapon(cplayer.readyweapon);
		rn_inspectammo=w?w.hdammotype1:null;
		rn_inspectwep=w;
	}

	//lock the inspected ammo to the weapon held when the key was pressed,
	//so switching weapons doesn't change what's being shown
	void RN_StartInspect(int len){
		inspecttimer=len;
		let w=hdweapon(cplayer.readyweapon);
		rn_inspectammo=w?w.hdammotype1:null;
		rn_inspectwep=w;
		rn_inspectweaponly=false;
	}

	// ------------------------------------------------------------
	// Ticking
	// ------------------------------------------------------------
	override void Tick(){
		super.Tick();
		RN_CacheCvars();
		if(!cplayer)return;
		let pl=hdplayerpawn(cplayer.mo);
		if(!pl)return;

		//inspect ammo key: pressing sets hdrn_inspectreq (show + weapon motion);
		//while it's held, hdrn_inspecthold keeps the panel up, and the
		//fade-out timer only starts counting once it's released
		int inspectlength=int(clamp(rn_inspecttime?rn_inspecttime.GetFloat():3.,0.5,30.)*TICRATE);
		if(rn_inspectreq&&rn_inspectreq.GetInt()){
			rn_inspectreq.SetInt(0);
			RN_StartInspect(inspectlength);
			//ask the game side to play the mag check motion on the weapon
			EventHandler.SendNetworkEvent("hdrn_magcheck");
		}
		if(rn_inspecthold&&rn_inspecthold.GetInt()&&inspecttimer>0)inspecttimer=max(inspecttimer,inspectlength);

		//optionally also show it on reload / secondary reload (User1) /
		//unload (User4) - but only if the weapon actually starts doing it.
		//After the press we watch the weapon for a few tics: if it leaves its
		//idle states (Ready/ReadyEnd/Nope) it's really reloading/unloading.
		bool reloading=!!(cplayer.cmd.buttons&(BT_RELOAD|BT_USER1|BT_USER4));
		if(
			reloading
			&&!rn_lastreload
			&&rn_inspectonreload
			&&rn_inspectonreload.GetBool()
		){
			rn_reloadwatch=10;
			rn_reloadwatchwep=hdweapon(cplayer.readyweapon);
		}
		rn_lastreload=reloading;
		if(rn_reloadwatch>0){
			rn_reloadwatch--;
			let ww=hdweapon(cplayer.readyweapon);
			if(!ww||ww!=rn_reloadwatchwep)rn_reloadwatch=0;
			else{
				state cs=RN_WeaponState();
				if(cs&&!RN_WeaponIdle(ww,cs)){
					RN_StartInspect(inspectlength);
					rn_reloadwatch=0;
				}
			}
		}

		//holding reload / secondary reload keeps an open panel up, like
		//holding the inspect key (the timer starts once they're released)
		if(inspecttimer>0&&(cplayer.cmd.buttons&(BT_RELOAD|BT_USER1))){
			inspecttimer=max(inspecttimer,rn_inspectweaponly?RN_QUICKTICS:inspectlength);
		}

		//pump shotgun: a quick look at what's in the gun after each pump
		//(Alt Fire, only if the weapon really starts pumping)
		bool pumping=!!(cplayer.cmd.buttons&BT_ALTATTACK);
		let pw=hdweapon(cplayer.readyweapon);
		if(
			pumping
			&&!rn_lastpump
			&&pw&&pw is "Hunter"
			&&(!rn_showonpump||rn_showonpump.GetBool())
		){
			rn_pumpwatch=10;
			rn_pumpwatchwep=pw;
		}
		rn_lastpump=pumping;
		//holding pump keeps the quick look up
		if(pumping&&rn_inspectweaponly&&inspecttimer>0&&pw&&pw is "Hunter"){
			inspecttimer=max(inspecttimer,RN_QUICKTICS);
		}
		if(rn_pumpwatch>0){
			rn_pumpwatch--;
			if(!pw||pw!=rn_pumpwatchwep)rn_pumpwatch=0;
			else{
				state cs=RN_WeaponState();
				if(cs&&!RN_WeaponIdle(pw,cs)){
					RN_StartQuickInspect(RN_QUICKTICS);
					rn_pumpwatch=0;
				}
			}
		}
		if(inspecttimer>0)inspecttimer--;

		//smooth health / lost max health
		double lost=0;
		if(pl.healthcap>0)lost=max(0,100-pl.healthcap);
		rn_disphealth+=(pl.health-rn_disphealth)*0.3;
		rn_displost+=(lost-rn_displost)*0.2;
		//(ignore the 1hp-at-a-time drains from bleeding / max health)
		if(rn_lasthealth-pl.health>=3)rn_dmgflash=RN_DMGFLASHTICS;
		rn_lasthealth=pl.health;
		if(rn_dmgflash>0)rn_dmgflash--;

		//armour durability, smoothed
		let aw=HDArmourWorn(pl.FindInventory("HDArmourWorn",true));
		double atarget=0;
		if(aw){
			let def=getdefaultbytype((class<HDArmourWorn>)(aw.getclass()));
			int maxd=def?def.durability:aw.durability;
			atarget=clamp(aw.durability/double(max(1,maxd)),0.,1.);
		}
		rn_disparmour+=(atarget-rn_disparmour)*0.25;

		//ECG: a new beat starts whenever the heart's countdown is reset
		int bc=pl.beatcount;
		if(bc>rn_lastbeat){
			rn_wavepos=0;
			rn_waveamp=clamp(0.55+pl.bloodpressure*0.02,0.45,1.);
		}
		rn_lastbeat=bc;
		double v=0;
		if(rn_wavepos>=0&&rn_wavepos<RN_WAVELEN){
			v=RN_WAVE[rn_wavepos]*rn_waveamp;
			rn_wavepos++;
		}else rn_wavepos=-1;
		//jitter when hurt or in pain
		double noise=(100-clamp(pl.health,0,100))*0.003+(pl.inpain>0?0.08:0.);
		v+=(RN_Rand()-0.5)*noise;
		rn_ecg[rn_ecghead]=v;
		rn_ecghead=(rn_ecghead+1)%RN_ECGN;

		if(pl.beatmax>0){
			double target=(TICRATE*60.)/pl.beatmax;
			if(rn_bpm<=0)rn_bpm=target;
			else rn_bpm+=(target-rn_bpm)*0.08;
		}

		//"auto" inventory mode: show for a while after selection changes
		if(cplayer.mo.invsel!=rn_lastinvsel)rn_invtimer=RN_INVSHOWTICS;
		rn_lastinvsel=cplayer.mo.invsel;
		if(rn_invtimer>0)rn_invtimer--;

		//BFG: keep its batteries on screen while charging (holding fire)
		let bfgw=hdweapon(cplayer.readyweapon);
		if(bfgw&&bfgw is "BFG9K"&&(cplayer.cmd.buttons&BT_ATTACK)){
			inspecttimer=max(inspecttimer,RN_FADETICS+4);
			rn_inspectwep=bfgw;
			rn_inspectammo=bfgw.hdammotype1;
			rn_inspectweaponly=false;
		}

		//flash the fire mode label when it changes (not when switching weapons)
		let fmw=hdweapon(cplayer.readyweapon);
		string fmnow=RN_FireMode(fmw);
		if(fmw==rn_lastmodewep&&fmnow!=rn_lastmode)rn_modeflash=35;
		rn_lastmode=fmnow;
		rn_lastmodewep=fmw;
		if(rn_modeflash>0)rn_modeflash--;

		//compass angle history (for interpolation between tics).
		//with inertia on, the card behaves like a liquid-damped compass:
		//a weak pull towards the real heading and a lot of drag, so it
		//glides there slowly and settles with at most a small swing
		double target=pl.angle;
		if(!rn_anginit){
			rn_angprev=target;
			rn_angcur=target;
			rn_cmpvel=0;
			rn_anginit=true;
		}else rn_angprev=rn_angcur;
		int elastic=rn_compasselastic?rn_compasselastic.GetInt():1;
		double diff=Actor.deltaangle(rn_angcur,target);
		if(elastic<=0||abs(diff)>150.){
			//off, or a teleport/instant turn: snap
			rn_angcur=target;
			rn_cmpvel=0;
		}else{
			//(values: 3 light, 1 smooth, 2 heavy - 3 was added later)
			//light:  ~0.45 s to settle, no visible swing on a 90 deg turn
			//smooth: ~0.9 s to settle, ~1 deg past the mark
			//heavy:  ~1.2 s to settle, ~5 deg swing
			double k=0.03,damp=0.26;					//smooth
			if(elastic==3){k=0.07;damp=0.42;}		//light
			else if(elastic==2){k=0.02;damp=0.18;}	//heavy
			rn_cmpvel=rn_cmpvel*(1.-damp)+diff*k;
			rn_angcur+=rn_cmpvel;
		}

		//jumpy fill for a ZM66 with a refilled (dirty) mag
		rn_glitchnum=10+int(RN_Rand()*90);	//same range HD uses
	}


	// ------------------------------------------------------------
	// Main draw
	// ------------------------------------------------------------
	override void Draw(int state,double TicFrac){
		rn_ticfrac=TicFrac;
		RN_CacheCvars();
		if(!RN_Enabled()){
			super.Draw(state,TicFrac);
			return;
		}
		if(!cplayer)return;
		hpl=hdplayerpawn(cplayer.mo);
		if(!hpl)return;
		cplayer.inventorytics=0;

		if(automapactive){
			DrawAutomapHUD(ticfrac);
			DrawAutomapStuff();
		}else if(cplayer.mo==cplayer.camera){
			DrawAlwaysStuff(ticfrac);
			if(hpl.health>0){
				BeginHUD(forcescaled:false);
				if(
					state<=HUD_Fullscreen
					&&hudlevel>0
				)RN_DrawHUD(ticfrac);
				else{
					let www=hdweapon(cplayer.readyweapon);
					if(www&&www.balwaysshowstatus)RN_DrawWeaponStatusShifted(www);
				}
			}
		}

		//heat
		double heatamt=Heat.GetAmount(hpl);
		if(heatamt>3)fill(color(
			int(RN_Rand()*5)+clamp(int(heatamt),0,64)
		,160,100,40),0,0,screen.getwidth(),screen.getheight());

		//blacking out
		if(hpl.blackout>0)fill(
			color(hpl.blackout,6,2,0),0,0,screen.getwidth(),screen.getheight()
		);

		if(hpl.health<1)drawtip();
		if(idmypos)drawmypos();
	}

	// ------------------------------------------------------------
	// HUD safe zone: pushes every corner of the HUD inwards
	// ------------------------------------------------------------
	//margins in real screen pixels (x = from left/right, y = from top/bottom)
	vector2 RN_SafeMargins(){
		double sw=screen.GetWidth();
		double sh=screen.GetHeight();
		double mx=0,my=0;

		//limit the HUD to an aspect ratio box (for ultrawide screens)
		int asp=rn_safeaspect?rn_safeaspect.GetInt():0;
		double ratio=0;
		if(asp==1)ratio=16./9.;
		else if(asp==2)ratio=16./10.;
		else if(asp==3)ratio=4./3.;
		else if(asp==4)ratio=21./9.;
		if(ratio>0)mx=max(0,(sw-sh*ratio)*0.5);

		//extra margins, in percent of the screen
		if(rn_safex)mx+=sw*clamp(rn_safex.GetFloat(),0.,40.)*0.01;
		if(rn_safey)my+=sh*clamp(rn_safey.GetFloat(),0.,40.)*0.01;
		return (mx,my);
	}
	//adds to the current 2D offset; returns the previous one for restoring
	vector2 RN_AddOffset(double dx,double dy){
		vector2 cur=screen.SetOffset(0,0);
		screen.SetOffset(cur.x+dx,cur.y+dy);
		return cur;
	}

	void RN_DrawHUD(double ticfrac){
		if(hdspectator(hpl))return;
		double alf=blurred?0.2:1.;

		vector2 sm=RN_SafeMargins();
		vector2 so;

		//bottom left
		so=RN_AddOffset(sm.x,-sm.y);
		RN_DrawPaperdoll(alf);
		screen.SetOffset(so.x,so.y);

		RN_DrawAmmoPanel();
		RN_DrawTopRight();

		//bottom centre
		so=RN_AddOffset(0,-sm.y);
		RN_DrawInspect();
		screen.SetOffset(so.x,so.y);

		//compass, top centre
		so=RN_AddOffset(0,sm.y);
		RN_DrawCompass();
		screen.SetOffset(so.x,so.y);

		//frags, top left
		so=RN_AddOffset(sm.x,sm.y);
		if(deathmatch||fraglimit>0)drawstring(
			mHUDFont,FormatNumber(CPlayer.fragcount),
			(6,6),DI_SCREEN_LEFT_TOP|DI_TEXT_ALIGN_LEFT,
			Font.CR_RED
		);
		screen.SetOffset(so.x,so.y);

		if(hudlevel==2)RN_DrawFullHudExtras();

		//object description
		drawstring(
			pnewsmallfont,hpl.viewstring,
			(0,20),DI_SCREEN_CENTER|DI_TEXT_ALIGN_CENTER,
			Font.CR_GREY,0.4,scale:(1,1)
		);

		drawtip();

		//debug centre line
		if(hd_debug)fill(color(96,24,96,18),-0.3,0,0.6,100,DI_SCREEN_CENTER);
	}


	// ------------------------------------------------------------
	// Paper doll + ECG (bottom left)
	// ------------------------------------------------------------
	color RN_Mix(color a,color b,double t){
		t=clamp(t,0.,1.);
		return color(255,
			int(a.r+(b.r-a.r)*t),
			int(a.g+(b.g-a.g)*t),
			int(a.b+(b.b-a.b)*t)
		);
	}
	color RN_HealthColour(double f){
		color cwhite=color(255,240,240,240);
		color cyellow=color(255,240,205,50);
		color corange=color(255,235,120,25);
		color cr=RN_Red();
		if(f>=0.7)return cwhite;
		if(f>=0.5)return RN_Mix(cyellow,cwhite,(f-0.5)/0.2);
		if(f>=0.3)return RN_Mix(corange,cyellow,(f-0.3)/0.2);
		if(f>=0.12)return RN_Mix(cr,corange,(f-0.12)/0.18);
		return cr;
	}

	//texture layout (px): 136x256, 4px per sprite pixel, 3 sprite px padding
	//body rows 16..240 (56 sprite px), armour shell HRNDOLA1-3 hugs the
	//body t sprite px out, vest 56..132
	enum HDRNDollTex{
		RN_DOLLTW=136,
		RN_DOLLTH=256,
		RN_BODYTOP=16,
		RN_BODYBOT=240,
		RN_BODYROWS=56,
		RN_VESTTOP=56,
		RN_VESTBOT=132,
	}

	//worn armour, its colour and how intact it is
	HDArmourWorn RN_GetArmour(){
		return HDArmourWorn(hpl.FindInventory("HDArmourWorn",true));
	}
	color RN_ArmourColour(HDArmourWorn aw){
		if(aw is "BattleArmourWorn")return color(255,70,135,255);
		if(aw is "GarrisonArmourWorn")return color(255,70,200,80);
		return color(255,200,200,210);
	}
	int RN_ArmourFontColour(HDArmourWorn aw){
		if(aw is "BattleArmourWorn")return Font.CR_LIGHTBLUE;
		if(aw is "GarrisonArmourWorn")return Font.CR_GREEN;
		return Font.CR_WHITE;
	}
	double RN_ArmourFrac(HDArmourWorn aw){
		if(!aw)return 0;
		let def=getdefaultbytype((class<HDArmourWorn>)(aw.getclass()));
		int maxd=def?def.durability:aw.durability;
		if(maxd<1)maxd=1;
		return clamp(aw.durability/double(maxd),0.,1.);
	}
	int RN_GetArmourStyle(){
		return rn_armourstyle?rn_armourstyle.GetInt():1;
	}

	//draws "tex" at pos, clipped to its lower "frac" between texture rows top..bot
	void RN_DrawDrained(
		string tex,vector2 pos,double ts,int top,int bot,double frac,
		double alf,color col,int sflags
	){
		//snap to whole sprite pixels (4 texture px)
		int rows=max(1,(bot-top)/4);
		frac=ceil(frac*rows-0.001)/double(rows);
		if(frac<=0.001)return;
		double y0=pos.y+top*ts;
		double hh=(bot-top)*ts;
		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();
		SetClipRect(pos.x-2,y0+hh*(1.-frac),RN_DOLLTW*ts+4,hh*frac+2,sflags);
		DrawImage(tex,pos,sflags|DI_ITEM_LEFT_TOP,alf,scale:(ts,ts),col:col);
		screen.SetClipRect(cx,cy,cw,ch);
	}

	void RN_DrawPaperdoll(double alf){
		double ds=rn_dollscale?clamp(rn_dollscale.GetFloat(),0.3,3.):1.;
		double ts=ds*0.2;				//body is ~46 units tall at scale 1
		double dw=RN_DOLLTW*ts;
		double dh=RN_DOLLTH*ts;
		vector2 pos=(4-8*ts,-4-RN_BODYBOT*ts);
		vector2 sc=(ts,ts);
		int sflags=DI_SCREEN_LEFT_BOTTOM;
		int fl=RN_FLAGS_BL;

		double bodytop=pos.y+RN_BODYTOP*ts;
		double bodyh=(RN_BODYBOT-RN_BODYTOP)*ts;
		double pad=RN_BODYTOP*ts;

		double hf=clamp(rn_disphealth*0.01,0.,1.);
		double lf=clamp(rn_displost*0.01,0.,1.);
		color hc=RN_HealthColour(hf);

		let aw=RN_GetArmour();
		int astyle=aw?RN_GetArmourStyle():0;
		double af=clamp(rn_disparmour,0.,1.);
		color ac=aw?RN_ArmourColour(aw):color(255,255,255,255);
		color acdim=color(255,ac.r/4,ac.g/4,ac.b/4);

		//critical: pulse
		double pulse=1.;
		if(hf<0.25)pulse=0.7+0.3*sin(gametic*16.);

		int cx,cy,cw,ch;
		[cx,cy,cw,ch]=screen.GetClipRect();

		//empty silhouette
		DrawImage("HRNDOLLM",pos,fl,alf*0.5,scale:sc,col:color(255,22,22,22));

		//health, bottom up (drains from the top down)
		//snapped to whole sprite pixels so the cut never splits a pixel
		double fh=bodyh*ceil(hf*RN_BODYROWS-0.001)/RN_BODYROWS;
		if(fh>0.01){
			SetClipRect(pos.x-2,bodytop+bodyh-fh,dw+4,fh+2,sflags);
			DrawImage("HRNDOLLF",pos,fl,alf*pulse,scale:sc,col:hc);
			screen.SetClipRect(cx,cy,cw,ch);
		}

		//lost maximum health, top down, dark red with darker diagonal stripes
		if(lf>0.002){
			SetClipRect(pos.x-2,pos.y-2,dw+4,pad+bodyh*ceil(lf*RN_BODYROWS-0.001)/RN_BODYROWS+2,sflags);
			DrawImage("HRNDOLLX",pos,fl,alf,scale:sc);
			screen.SetClipRect(cx,cy,cw,ch);
		}

		//armour as a vest over the torso
		if(astyle==2){
			DrawImage("HRNVEST",pos,fl,alf*0.55,scale:sc,col:acdim);
			RN_DrawDrained("HRNVEST",pos,ts,RN_VESTTOP,RN_VESTBOT,af,alf*0.95,ac,sflags);
		}

		//damage flash
		if(rn_dmgflash>0)DrawImage(
			"HRNDOLLM",pos,fl,
			alf*0.6*rn_dmgflash/double(RN_DMGFLASHTICS),
			scale:sc,style:STYLE_Add,col:color(255,255,50,30)
		);

		if(astyle==1){
			//armour as a thick shell around the doll
			int sw=rn_armourwidth?clamp(rn_armourwidth.GetInt(),1,3):1;
			string shelltex="HRNDOLA"..sw;
			DrawImage(shelltex,pos,fl,alf*0.6,scale:sc,col:acdim);
			RN_DrawDrained(shelltex,pos,ts,RN_BODYTOP-4*sw,RN_BODYBOT+4*sw,af,alf*0.95,ac,sflags);
		}else{
			//plain outline
			color oc=hf<0.25?RN_Mix(color(255,230,230,230),RN_Red(),(1.-pulse)*3.):color(255,230,230,230);
			DrawImage("HRNDOLLO",pos,fl,alf*0.9,scale:sc,col:oc);
		}

		//optional health / armour numbers
		double numy=bodytop-7;
		if(
			(rn_showhpnum&&rn_showhpnum.GetBool())
			||hd_debug
		)drawstring(
			pnewsmallfont,FormatNumber(hpl.health),
			(pos.x+dw*0.5,numy),sflags|DI_TEXT_ALIGN_CENTER,
			Font.CR_WHITE,alf,scale:(0.5,0.5)
		);
		if(
			astyle
			&&rn_armournum
			&&rn_armournum.GetBool()
		)drawstring(
			pnewsmallfont,FormatNumber(aw.durability),
			(pos.x+dw-2,numy),sflags|DI_TEXT_ALIGN_RIGHT,
			RN_ArmourFontColour(aw),alf,scale:(0.45,0.45)
		);

		if(!rn_showecg||rn_showecg.GetBool())RN_DrawECG(pos.x+dw+2,ds,alf,hf);

		//encumbrance above the doll when the full HUD is up
		if(hudlevel==2&&hpl.enc)RN_DrawEncumbrance((pos.x+8*ts,bodytop),dw,alf);
	}
	color RN_Red(){return color(255,210,28,22);}

	void RN_DrawECG(double ex,double ds,double alf,double hf){
		double ew=38*ds;
		double eh=14*ds;
		double mid=-6-eh*0.5;
		int sflags=DI_SCREEN_LEFT_BOTTOM;

		//baseline
		fill(color(int(40*alf),255,255,255),ex,mid,ew,0.4,sflags);

		color ecol=hf<0.5?RN_HealthColour(hf):color(255,235,235,235);
		double stp=ew/(RN_ECGN-1);
		for(int i=0;i<RN_ECGN-1;i++){
			int a=(rn_ecghead+i)%RN_ECGN;
			int b=(rn_ecghead+i+1)%RN_ECGN;
			double y1=mid-rn_ecg[a]*eh*0.5;
			double y2=mid-rn_ecg[b]*eh*0.5;
			double top=min(y1,y2)-0.35;
			double hgt=abs(y1-y2)+0.7;
			int al=int(255*alf*(0.1+0.9*i/double(RN_ECGN-1)));
			fill(color(al,ecol.r,ecol.g,ecol.b),ex+i*stp,top,stp+0.35,hgt,sflags);
		}
		//leading dot
		int last=(rn_ecghead+RN_ECGN-1)%RN_ECGN;
		fill(color(int(255*alf),255,255,255),ex+ew-0.6,mid-rn_ecg[last]*eh*0.5-0.7,1.4,1.4,sflags);

		//heart rate
		int bpm=int(rn_bpm+0.5);
		int bcol=Font.CR_WHITE;
		if(bpm>=190||bpm<30)bcol=Font.CR_RED;
		else if(bpm>=150||bpm<45)bcol=Font.CR_GOLD;
		drawstring(
			pnewsmallfont,FormatNumber(bpm),
			(ex,mid-eh*0.5-9),sflags|DI_TEXT_ALIGN_LEFT,
			bcol,alf,scale:(0.6,0.6)
		);
		drawstring(
			pnewsmallfont,"BPM",
			(ex+NewSmallFont.StringWidth(FormatNumber(bpm))*0.6+2,mid-eh*0.5-7),
			sflags|DI_TEXT_ALIGN_LEFT,
			Font.CR_DARKGRAY,alf,scale:(0.4,0.4)
		);
	}

	void RN_DrawEncumbrance(vector2 pos,double dw,double alf){
		double pocketenc=hpl.pocketenc;
		int sflags=DI_SCREEN_LEFT_BOTTOM;
		double y=pos.y-24;
		drawstring(
			pnewsmallfont,"ENC "..formatnumber(int(hpl.enc)),
			(pos.x,y-6),sflags|DI_TEXT_ALIGN_LEFT,
			hpl.overloaded<0.8?Font.CR_WHITE:hpl.overloaded>1.6?Font.CR_RED:Font.CR_GOLD,
			alf,scale:(0.45,0.45)
		);
		double bw=32;
		fill(color(int(90*alf),255,255,255),pos.x,y,bw,1.2,sflags);
		if(hpl.maxpocketspace>0){
			double frac=clamp(pocketenc/hpl.maxpocketspace,0.,1.);
			bool overenc=pocketenc>hpl.maxpocketspace;
			fill(
				overenc?color(int(255*alf),216,194,42):color(int(230*alf),240,240,240),
				pos.x,y,bw*frac,1.2,sflags
			);
		}
	}


	// ------------------------------------------------------------
	// Weapon / ammo (bottom right)
	// ------------------------------------------------------------
	//weapons whose "readout" is really an on-screen menu (backpack, mag manager,
	//HERP/DERP controls...) - left exactly as HD draws them
	bool RN_IsMenuWeapon(hdweapon hdw){
		return hdw&&(
			hdw.balwaysshowstatus
			||hdw is "HDStorageItem"
			||hdw is "MagManager"
			||hdw is "PickupManager"
			||hdw is "DERPUsable"
			||hdw is "HERPUsable"
		);
	}
	//weapons that draw things around the crosshair (grenade, tripwire)
	//keep their readout in the default centre position
	bool RN_IsCentredWeapon(hdweapon hdw){
		return hdw&&(
			hdw is "HDGrenadeThrower"
			||hdw is "Tripwire"
		);
	}

	//HD weapons draw their readouts around the bottom centre of the screen.
	//We shift the whole 2D drawer so that point lands in the bottom right corner.
	void RN_DrawWeaponStatusShifted(weapon w,double yshift=0){
		let hdw=hdweapon(w);
		bool menuwep=RN_IsMenuWeapon(hdw);

		//HD shows the reserve ammo (spare mags + count) next to the readout
		//only while hudlevel==1; hide it, the inspect key does that job now
		int oldhudlevel=hudlevel;
		if(!menuwep&&hudlevel==1)hudlevel=0;

		vector2 sm=RN_SafeMargins();
		if(RN_ReplacesReadout(hdw)){
			//nothing: this weapon's ammo is shown by the inspect panel
		}else if(menuwep){
			drawweaponstatus(w);
		}else if(RN_IsCentredWeapon(hdw)){
			vector2 old=RN_AddOffset(0,-sm.y);
			drawweaponstatus(w);
			screen.SetOffset(old.x,old.y);
		}else{
			//anchor: above the BPM text, bottom left
			double ax,ay,ex;
			[ax,ay,ex]=RN_ReadoutAnchor();
			vector2 hs=GetHUDScale();
			vector2 old=RN_AddOffset(
				-screen.GetWidth()*0.5+ax*hs.x+sm.x,
				(ay+yshift)*hs.y-sm.y
			);
			drawweaponstatus(w);
			screen.SetOffset(old.x,old.y);
		}

		hudlevel=oldhudlevel;
		beginhud(forcescaled:false);
	}

	//alpha for a label with mode 0 = off, 1 = always, 2 = only while checking
	//the ammo (follows the inspect panel's fade)
	double RN_LabelAlpha(int mode,bool force){
		if(mode<=0)return 0;
		if(mode==1||force)return 1;
		return inspecttimer>0?clamp(inspecttimer/double(RN_FADETICS),0.,1.):0;
	}

	//where HD's weapon readout goes (bottom left, above the BPM number).
	//HD readouts reach ~40 units left of their origin, so the origin goes
	//42 units right of the BPM's left edge: the readout lines up with it.
	//returns origin x, origin y, and the BPM's left edge
	double,double,double RN_ReadoutAnchor(){
		double ds=rn_dollscale?clamp(rn_dollscale.GetFloat(),0.3,3.):1.;
		double ts=ds*0.2;
		double ex=(4-8*ts)+RN_DOLLTW*ts+2;
		return ex+42,-(17+14*ds),ex;
	}

	void RN_DrawAmmoPanel(){
		let w=cplayer.readyweapon;
		if(!w||w==WP_NOCHANGE)return;
		let hdw=hdweapon(w);

		RN_DrawWeaponStatusShifted(w);

		vector2 sm=RN_SafeMargins();
		vector2 so;

		//weapon name, above the readout
		so=RN_AddOffset(sm.x,-sm.y);
		//(each one: off / always / only while checking the ammo)
		double namealf=RN_LabelAlpha(rn_weaponname?rn_weaponname.GetInt():2,false);
		if(namealf>0){
			double ax,ay,ex;
			[ax,ay,ex]=RN_ReadoutAnchor();
			drawstring(
				pnewsmallfont,w.GetTag(),
				(ex,ay-24),DI_SCREEN_LEFT_BOTTOM|DI_TEXT_ALIGN_LEFT,
				Font.CR_WHITE,0.85*namealf,scale:(0.5,0.5)
			);
		}
		//fire mode, for the weapons whose HD readout we replaced
		//(changing it always shows it briefly, even in "while checking" mode)
		if(RN_ReplacesReadout(hdw)){
			string fm=RN_FireMode(hdw);
			double fmalf=RN_LabelAlpha(rn_firemodeshow?rn_firemodeshow.GetInt():2,rn_modeflash>0);
			if(fm!=""&&fmalf>0){
				double ax,ay,ex;
				[ax,ay,ex]=RN_ReadoutAnchor();
				drawstring(
					pnewsmallfont,fm,
					(ex,ay-15),DI_SCREEN_LEFT_BOTTOM|DI_TEXT_ALIGN_LEFT,
					rn_modeflash>0?Font.CR_GOLD:Font.CR_WHITE,fmalf,scale:(0.6,0.6)
				);
			}
		}
		screen.SetOffset(so.x,so.y);

		//weapon sprite (bottom right, above the inventory)
		so=RN_AddOffset(-sm.x,-sm.y);
		if(
			hudlevel==2
			||cvar.getcvar("hd_hudsprite",cplayer).getbool()
			||!cvar.getcvar("r_drawplayersprites",cplayer).getbool()
		)drawselectedweapon(-8,-46,DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM);
		screen.SetOffset(so.x,so.y);
	}


	// ------------------------------------------------------------
	// Inventory (bottom right) / keys and worn items (top right)
	// ------------------------------------------------------------
	void RN_DrawTopRight(){
		int invmode=rn_inventory?rn_inventory.GetInt():2;
		bool showinv=
			invmode==1
			||(invmode==2&&(rn_invtimer>0||hudlevel==2))
		;
		vector2 hs=GetHUDScale();
		double sw=screen.GetWidth();
		double sh=screen.GetHeight();
		double y=6;
		vector2 sm=RN_SafeMargins();
		vector2 so;

		if(showinv&&cplayer.mo.invsel){
			//reuse HD's own inventory selector (with its animation),
			//shifted from the bottom centre to the bottom right corner
			int mxht=-4-mIndexFont.mFont.GetHeight();
			vector2 old=RN_AddOffset(sw*0.5-52*hs.x-sm.x,-sm.y);
			DrawSurroundingInv(25,-4,42,mxht,DI_SCREEN_CENTER_BOTTOM,0);
			DrawInvSel(25,-14,42,mxht,DI_SCREEN_CENTER_BOTTOM);
			screen.SetOffset(old.x,old.y);
			//full inventory grid (hold Use) goes in the top right
			if(hudlevel==2){
				so=RN_AddOffset(-sm.x,sm.y);
				y=RN_DrawInvGrid(y);
				screen.SetOffset(so.x,so.y);
			}
		}

		if(!rn_showitems||rn_showitems.GetBool()){
			so=RN_AddOffset(-sm.x,sm.y);
			//keys
			int k=0;
			for(int i=0;i<6;i++){
				if(!hpl.countinv(RN_KEYITEMS[i]))continue;
				drawimage(RN_KEYGFX[i],(-8-k*9,y),DI_SCREEN_RIGHT_TOP|DI_ITEM_RIGHT_TOP);
				k++;
			}
			if(k)y+=10;

			//worn items (armour, blood bag, radsuit...) use their automap layout,
			//which starts at (4,86) from the top left, shifted to the top right
			//(armour is skipped when it's shown on the paper doll)
			bool armourondoll=RN_GetArmourStyle()>0;
			vector2 old=RN_AddOffset(sw-46*hs.x,(y-84)*hs.y);
			for(let item=hpl.inv;item!=null;item=item.inv){
				let hp=HDPickup(item);
				if(!hp)continue;
				if(armourondoll&&hp is "HDArmourWorn")continue;
				hp.DrawHudStuff(self,hpl,HDSB_AUTOMAP,DI_TOPLEFT);
			}
			screen.SetOffset(old.x,old.y);
			screen.SetOffset(so.x,so.y);
		}
	}

	double RN_DrawInvGrid(double y){
		int i=0;
		for(let item=cplayer.mo.inv;item!=null;item=item.inv){
			if(
				!item.binvbar
				&&item!=cplayer.mo.invsel
			)continue;
			textureid icon;vector2 applyscale;
			[icon,applyscale]=geticon(item,0);
			bool isthis=item==cplayer.mo.invsel;
			let ivsh=hdpickup(item);
			let ivsw=hdweapon(item);
			drawtexture(icon,
				(-14-(i%5)*18,y+16+18*(i/5)),
				DI_SCREEN_RIGHT_TOP|DI_ITEM_CENTER_BOTTOM
				|((
					(ivsh&&ivsh.bdroptranslation)
					||(ivsw&&ivsw.bdroptranslation)
				)?DI_TRANSLATABLE:0),
				alpha:isthis?1.:0.6,scale:applyscale*(isthis?1.:0.6)
			);
			i++;
		}
		return y+18*((i+4)/5)+4;
	}


	// ------------------------------------------------------------
	// Magazine inspection (bottom centre)
	// ------------------------------------------------------------
	string,double,double RN_MagShape(class<Inventory> t){
		//subclasses first
		if((class<HD9mMag30>)(t))return "HRNMGC",9.,27.;
		if((class<HD9mMag15>)(t))return "HRNMGB",8.,20.;
		if((class<HD7mClip>)(t))return "HRNMGE",8.,22.;
		if((class<HD7mMag>)(t))return "HRNMGA",12.,27.;
		if((class<HD4mMag>)(t))return "HRNMGA",12.,27.;
		if((class<HDBattery>)(t))return "HRNMGD",12.,20.;
		return "HRNMGC",9.,27.;
	}
	//ammo colour (fill and outline of mags, rounds, cells, shells...):
	//a chosen colour, or the player's colour like HD's own ammo bars
	color RN_AmmoFill(){
		color c=color(255,240,240,240);
		if(rn_ammousepcol&&rn_ammousepcol.GetBool())c=sbcolour;
		else if(rn_ammocolor)c=rn_ammocolor.GetInt();
		return color(255,c.r,c.g,c.b);
	}
	color RN_AmmoLine(){
		color c=RN_AmmoFill();
		return color(255,int(c.r*0.95),int(c.g*0.95),int(c.b*0.95));
	}

	//draws a silhouette filled from the bottom up by "frac"
	void RN_DrawFilledShape(
		string shp,vector2 pos,double sc,double mw,double mh,
		double frac,double alf,int sflags,
		color fillcol=0,color linecol=0
	){
		//0 = the configurable ammo colour
		if(fillcol==0)fillcol=RN_AmmoFill();
		if(linecol==0)linecol=RN_AmmoLine();
		vector2 tsc=(sc,sc)*0.25;
		int fl=sflags|DI_ITEM_LEFT_TOP;
		DrawImage(shp.."F",pos,fl,alf*0.4,scale:tsc,col:color(255,18,18,18));
		if(frac>0.){
			double bodyh=mh-sc*2;
			int cx,cy,cw,ch;
			[cx,cy,cw,ch]=screen.GetClipRect();
			SetClipRect(pos.x-1,pos.y+sc+bodyh*(1.-frac),mw+2,bodyh*frac+sc+1,sflags);
			DrawImage(shp.."F",pos,fl,alf,scale:tsc,col:fillcol);
			screen.SetClipRect(cx,cy,cw,ch);
		}
		DrawImage(shp.."O",pos,fl,alf*0.9,scale:tsc,col:linecol);
	}

	// ------------------------------------------------------------
	// Inspect panel: a row of items (bottom centre), built per weapon.
	// Groups are separated by a wider gap:
	//   [what's in the gun] [spare primary ammo] [spare secondary ammo]
	// ------------------------------------------------------------
	enum HDRNItemTypes{
		RN_IT_FILL=0,		//silhouette filled bottom-up (mags, cells)
		RN_IT_ROUND=1,		//chambered round
		RN_IT_GREN=2,		//rifle grenade
		RN_IT_TEXT=3,		//"xN"
		RN_IT_ICON=4,		//inventory icon of an item class
		RN_IT_STACK=5,		//column of small boxes (queued mags), bottom-up
		RN_IT_SHELL=6,		//shotgun shell: hull = tube, brass = chamber
		RN_IT_SADDLE=7,		//side saddle shells: 2 columns of 6 small boxes

		RN_ST_NORMAL=0,		//fill styles
		RN_ST_DIRTY=1,		//red, jumpy fill
		RN_ST_EMPTYSLOT=2,	//no mag/cell in this slot: faint outline
		RN_ST_LIVE=1,		//round/grenade styles
		RN_ST_SPENT=0,

		RN_EX_HARNESS=512,	//extra: "harness" label above
		RN_EX_JAM=1024,		//extra: weapon jammed (red stripes)
		RN_STACKCELLH=11,	//height of the small battery on top of a stack
	}
	const RN_SHELLSCALE=1.6;	//shotgun shell drawn bigger than its texture
	const RN_SADDLESCALE=0.8;	//side saddle boxes
	array<int> rn_ittype;
	array<string> rn_ittex;
	array<double> rn_itw;
	array<double> rn_ith;
	array<double> rn_itfrac;
	array<int> rn_itstyle;
	array<int> rn_itnum;
	array<int> rn_itnumcol;
	array<int> rn_itgroup;
	array<int> rn_itextra;

	void RN_ClearItems(){
		rn_ittype.clear();rn_ittex.clear();rn_itw.clear();rn_ith.clear();
		rn_itfrac.clear();rn_itstyle.clear();rn_itnum.clear();rn_itnumcol.clear();
		rn_itgroup.clear();rn_itextra.clear();
	}
	void RN_AddItem(
		int type,string tex,double w,double h,int group,
		double frac=0,int style=0,int num=-1,int numcol=Font.CR_WHITE,int extra=0
	){
		rn_ittype.push(type);rn_ittex.push(tex);rn_itw.push(w);rn_ith.push(h);
		rn_itfrac.push(frac);rn_itstyle.push(style);rn_itnum.push(num);
		rn_itnumcol.push(numcol);rn_itgroup.push(group);rn_itextra.push(extra);
	}
	//a mag/cell silhouette; frac<0 = slot without a mag
	void RN_AddMag(class<Inventory> magtype,double frac,int group,int style=0,int num=-1,int numcol=Font.CR_WHITE,int extra=0){
		string shp;double uw,uh;
		[shp,uw,uh]=RN_MagShape(magtype);
		if(frac<0){style=RN_ST_EMPTYSLOT;frac=0;}
		RN_AddItem(RN_IT_FILL,shp,uw+2,uh+2,group,frac,style,num,numcol,extra);
	}

	//spare ammo of one type, as its own group
	void RN_AddSpares(class<HDPickup> t,int group){
		if(!t)return;
		bool numbers=rn_magnumbers&&rn_magnumbers.GetBool();
		let magtype=(class<HDMagAmmo>)(t);
		if(magtype){
			let mm=hdmagammo(hpl.findinventory(magtype));
			if(!mm)return;
			int full=max(1,mm.GetMagHudCount(mm.maxperunit));
			for(int i=0;i<mm.mags.size();i++){
				int cnt=mm.GetMagHudCount(mm.mags[i]);
				RN_AddMag(magtype,clamp(cnt/double(full),0.,1.),group,num:numbers?cnt:-1);
			}
			return;
		}
		//loose rounds: icon + count (shotgun shells: just the count)
		let inv=hpl.findinventory(t);
		int cnt=inv?inv.amount:0;
		if((class<HDRocketAmmo>)(t))RN_AddItem(RN_IT_GREN,"HRNGRN",6,12,group,style:cnt?RN_ST_LIVE:RN_ST_SPENT);
		else if(inv&&!(class<HDShellAmmo>)(t))RN_AddItem(RN_IT_ICON,t.getclassname(),10,10,group);
		RN_AddItem(RN_IT_TEXT,"x"..cnt,NewSmallFont.StringWidth("x"..cnt)*0.6,8,group,style:cnt?1:0);
	}

	//what's inside the gun, for the weapons we know how to read.
	//returns: known, whether to also list the secondary ammo
	bool,bool RN_AddWeaponGroup(hdweapon w){
		if(!w)return false,false;
		bool numbers=rn_magnumbers&&rn_magnumbers.GetBool();

		//family 1: one mag + chamber (+ grenade launcher)
		int lcnt,lcap,lchamber;bool lknown,ldirty;
		[lknown,lcnt,lcap,lchamber,ldirty]=RN_LoadedMag(w);
		if(lknown){
			//the ZM66 has its own digital counter: always shown, in red
			bool hascounter=w is "ZM66AssaultRifle";
			int num=-1;
			if(hascounter||(numbers&&lcnt>=0)){
				num=ldirty?rn_glitchnum:(max(lcnt,0)+(lchamber==2?1:0));
			}
			RN_AddMag(w.hdammotype1,lcnt<0?-1.:lcnt/double(max(1,lcap)),0,
				ldirty?RN_ST_DIRTY:RN_ST_NORMAL,num,
				(ldirty||hascounter)?Font.CR_RED:Font.CR_WHITE
			);
			RN_AddItem(RN_IT_ROUND,"HRNRND",5,10,0,style:lchamber==2?RN_ST_LIVE:RN_ST_SPENT);

			bool haslauncher=false,glloaded=false;
			if(w is "ZM66AssaultRifle"){
				haslauncher=!(w.weaponstatus[0]&ZM66F_NOLAUNCHER);
				glloaded=!!(w.weaponstatus[0]&ZM66F_GRENADELOADED);
			}else if(w is "LiberatorRifle"){
				haslauncher=!(w.weaponstatus[0]&LIBF_NOLAUNCHER);
				glloaded=!!(w.weaponstatus[0]&LIBF_GRENADELOADED);
			}
			if(haslauncher)RN_AddItem(RN_IT_GREN,"HRNGRN",6,12,0,style:glloaded?RN_ST_LIVE:RN_ST_SPENT);
			return true,haslauncher;
		}

		//Hunter: one shell. hull fill = shells in the tube, brass = chamber
		//(white = live, dark = spent, whole shell faint = nothing chambered),
		//red stripes when jammed; then the side saddle shells
		if(w is "Hunter"){
			int tube=max(0,w.weaponstatus[HUNTS_TUBE]);
			int tsize=max(1,w.weaponstatus[HUNTS_TUBESIZE]);
			int ch=clamp(w.weaponstatus[HUNTS_CHAMBER],0,2);
			bool jam=!!(w.weaponstatus[0]&HUNTF_JAMMED);
			RN_AddItem(RN_IT_SHELL,"HRNSH",9*RN_SHELLSCALE,18.25*RN_SHELLSCALE,0,
				clamp(tube/double(tsize),0.,1.),ch,
				numbers?tube+(ch==2?1:0):-1,Font.CR_WHITE,
				jam?RN_EX_JAM:0
			);
			RN_AddItem(RN_IT_SADDLE,"",7*RN_SADDLESCALE*2,4.5*RN_SADDLESCALE*6,0,
				extra:clamp(w.weaponstatus[SHOTS_SIDESADDLE],0,12)
			);
			return true,false;
		}

		//Vulcanette: feeding mag + a round that drains with the rounds left
		//in the 5 rotating chambers + the 4 queued mags as stacked boxes
		if(w is "Vulcanette"){
			int m=w.weaponstatus[VULCS_MAG1];
			bool dirty=m>=0&&!!(w.weaponstatus[0]&VULCF_DIRTYMAG);
			int num=m<0?-1:(dirty?rn_glitchnum:min(m,50));
			RN_AddMag("HD4mMag",m<0?-1.:min(m,50)/50.,0,
				dirty?RN_ST_DIRTY:RN_ST_NORMAL,num,Font.CR_RED
			);
			int chambered=0;
			for(int i=0;i<5;i++){
				if(w.weaponstatus[VULCS_CHAMBER1+i]>0)chambered++;
			}
			//column: 4 queued-mag boxes with a small battery on top
			//(frac = battery charge, -1 = no battery)
			int queued=0;
			for(int i=1;i<5;i++){
				if(w.weaponstatus[VULCS_MAG1+i]>=0)queued|=(1<<(i-1));
			}
			int b=w.weaponstatus[VULCS_BATTERY];
			RN_AddItem(RN_IT_STACK,"HRNBOX",7,4.5*4+RN_STACKCELLH+1,0,
				frac:b<0?-1.:b/20.,extra:queued
			);
			//then the round that drains with the rounds left in the chambers
			RN_AddItem(RN_IT_FILL,"HRNRND",5,10,0,chambered/5.,chambered?RN_ST_NORMAL:RN_ST_EMPTYSLOT);
			return true,true;
		}

		//BFG: two battery slots, both must be full to fire
		if(w is "BFG9K"){
			int b1=w.weaponstatus[BFGS_BATTERY];
			int b2=w.weaponstatus[BFGS_CHARGE];
			int ex=(w.weaponstatus[0]&BFGF_STRAPPED)?RN_EX_HARNESS:0;
			RN_AddMag("HDBattery",b1<0?-1.:b1/20.,0,num:(numbers&&b1>=0)?b1:-1,extra:ex);
			RN_AddMag("HDBattery",b2<0?-1.:b2/20.,0,num:(numbers&&b2>=0)?b2:-1);
			return true,false;
		}

		//single battery weapons
		int bslot=-1;
		if(w is "ThunderBuster")bslot=TBS_BATTERY;
		else if(w is "Lumberjack")bslot=CSAWS_BATTERY;
		if(bslot>=0){
			int b=w.weaponstatus[bslot];
			RN_AddMag("HDBattery",b<0?-1.:b/20.,0,num:(numbers&&b>=0)?b:-1);
			return true,false;
		}
		return false,false;
	}

	void RN_DrawInspect(){
		//"always show the weapon's ammo": with no panel open, the gun's own
		//group stays on screen (spares still only show the usual ways)
		bool always=rn_alwaysweapon&&rn_alwaysweapon.GetBool();
		bool panel=inspecttimer>0;
		if(!panel&&!always)return;
		double alf=panel?clamp(inspecttimer/double(RN_FADETICS),0.,1.):0.;
		double walf=always?1.:alf;	//alpha of the weapon's own group
		int sflags=DI_SCREEN_CENTER_BOTTOM;

		//build the row
		RN_ClearItems();
		hdweapon lw;
		bool weaponly;
		if(panel){
			lw=rn_inspectwep;
			if(lw&&lw.owner!=hpl)lw=null;
			weaponly=rn_inspectweaponly;
		}else{
			lw=hdweapon(cplayer.readyweapon);
			weaponly=true;
		}
		bool known,showammo2;
		[known,showammo2]=RN_AddWeaponGroup(lw);
		if(!panel&&!known)return;
		if(panel&&(!weaponly||!known)){
			RN_AddSpares(rn_inspectammo,1);
			if(known&&showammo2&&lw.hdammotype2)RN_AddSpares(lw.hdammotype2,2);
		}

		int n=rn_ittype.size();
		if(n<1){
			drawstring(
				pnewsmallfont,StringTable.Localize(rn_inspectammo?"$HDRN_NOMAGS":"$HDRN_NOAMMO"),
				(0,-16),sflags|DI_TEXT_ALIGN_CENTER,
				Font.CR_DARKGRAY,alf,scale:(0.5,0.5)
			);
			return;
		}

		//layout
		//(the slider is shifted by +0.3: 1.0 on the menu = 0.7 internal size)
		double sc=rn_magscale?clamp(rn_magscale.GetFloat()-0.3,0.2,3.):0.7;
		double gap=3;
		array<double> gaps;
		double total=0;
		for(int i=0;i<n;i++){
			double g=0;
			if(i>0){
				//new group: wide gap, except a lone "xN" which sits closer
				if(rn_itgroup[i]!=rn_itgroup[i-1])g=rn_ittype[i]==RN_IT_TEXT?gap:gap*3;
				else if(
					rn_ittype[i]==RN_IT_ROUND||rn_ittype[i]==RN_IT_GREN
					||rn_ittype[i]==RN_IT_TEXT||rn_ittype[i]==RN_IT_STACK
					||rn_ittype[i]==RN_IT_SADDLE
					||rn_ittex[i]=="HRNRND"
				)g=gap*0.5;
				else g=gap;
			}
			gaps.push(g);
			total+=g+rn_itw[i];
		}
		double maxw=220;
		if(total*sc>maxw)sc=max(0.35,maxw/total);
		double x=-total*sc*0.5;
		double bottom=-3;	//almost touching the bottom of the screen

		color afill=RN_AmmoFill();
		color aline=RN_AmmoLine();
		for(int i=0;i<n;i++){
			double ia=rn_itgroup[i]==0?walf:alf;
			x+=gaps[i]*sc;
			double w=rn_itw[i]*sc;
			double h=rn_ith[i]*sc;
			vector2 pos=(x,bottom-h);
			int fl=sflags|DI_ITEM_LEFT_TOP;
			vector2 tsc=(sc,sc)*0.25;
			int type=rn_ittype[i];
			int st=rn_itstyle[i];
			int ex=rn_itextra[i];
			double labely=pos.y;

			if(type==RN_IT_FILL){
				string tex=rn_ittex[i];
				if(st==RN_ST_EMPTYSLOT){
					DrawImage(tex.."O",pos,fl,ia*0.3,scale:tsc);
				}else if(st==RN_ST_DIRTY){
					//dirty mag: amount unknown, so the whole mag gets the
					//lost-max-health stripes, pulsing slowly
					//solid dark-stripe colour underneath, so only the lighter
					//stripes fade in and out (strong pulse: ~0 to full)
					double pulse=0.05+0.95*(0.5+0.5*sin(gametic*6.));
					DrawImage(tex.."F",pos,fl,ia,scale:tsc,col:color(255,34,11,11));
					DrawImage(tex.."X",pos,fl,ia*pulse,scale:tsc);
					DrawImage(tex.."O",pos,fl,ia*0.9,scale:tsc,col:color(255,225,60,50));
				}else RN_DrawFilledShape(tex,pos,sc,w,h,rn_itfrac[i],ia,sflags);
			}else if(type==RN_IT_ROUND||type==RN_IT_GREN){
				//absent (nothing in the chamber/launcher) = faint outline,
				//same as a mag slot with no mag in it
				string tex=rn_ittex[i];
				if(st==RN_ST_LIVE){
					DrawImage(tex.."F",pos,fl,ia,scale:tsc,col:afill);
					DrawImage(tex.."O",pos,fl,ia*0.9,scale:tsc,col:aline);
				}else DrawImage(tex.."O",pos,fl,ia*0.3,scale:tsc);
			}else if(type==RN_IT_TEXT){
				drawstring(
					pnewsmallfont,rn_ittex[i],
					(x,bottom-NewSmallFont.GetHeight()*0.6*sc),
					sflags|DI_TEXT_ALIGN_LEFT,
					st?Font.CR_WHITE:Font.CR_DARKGRAY,ia,scale:(0.6,0.6)*sc
				);
			}else if(type==RN_IT_ICON){
				let inv=hpl.findinventory((class<Inventory>)(rn_ittex[i]));
				if(inv)drawinventoryicon(inv,(x+w*0.5,bottom),sflags|DI_ITEM_CENTER_BOTTOM,ia);
			}

			//shotgun shell (drawn bigger, about the size of a rifle mag)
			if(type==RN_IT_SHELL){
				double ssc=sc*RN_SHELLSCALE;
				double pxs=0.25*ssc;	//HUD units per texture pixel
				tsc=(ssc,ssc)*0.25;
				bool jam=!!(ex&RN_EX_JAM);
				if(st==0&&!jam){
					//nothing chambered: whole shell faint, but the tube
					//still shows how many shells are loaded
					DrawImage("HRNSHTF",pos,fl,ia*0.15,scale:tsc,col:color(255,18,18,18));
					double topy=pos.y+(51-45*rn_itfrac[i])*pxs;
					int cx,cy,cw,ch;
					[cx,cy,cw,ch]=screen.GetClipRect();
					SetClipRect(pos.x-1,topy,w+2,pos.y+h-topy+1,sflags);
					DrawImage("HRNSHTF",pos,fl,ia*0.35,scale:tsc,col:afill);
					screen.SetClipRect(cx,cy,cw,ch);
					DrawImage("HRNSHOF",pos,fl,ia*0.3,scale:tsc);
				}else{
					DrawImage("HRNSHTF",pos,fl,ia*0.4,scale:tsc,col:color(255,18,18,18));
					DrawImage("HRNSHBF",pos,fl,ia*0.4,scale:tsc,col:color(255,18,18,18));
					//tube fill line (hull interior is texture rows 6..50)
					double topy=pos.y+(51-45*rn_itfrac[i])*pxs;
					int cx,cy,cw,ch;
					[cx,cy,cw,ch]=screen.GetClipRect();
					SetClipRect(pos.x-1,topy,w+2,pos.y+h-topy+1,sflags);
					if(jam){
						//filled tube + chamber in pulsing red stripes
						double pulse=0.05+0.95*(0.5+0.5*sin(gametic*6.));
						DrawImage("HRNSHKF",pos,fl,ia,scale:tsc,col:color(255,34,11,11));
						DrawImage("HRNSHXF",pos,fl,ia*pulse,scale:tsc);
					}else{
						DrawImage("HRNSHTF",pos,fl,ia,scale:tsc,col:afill);
					}
					screen.SetClipRect(cx,cy,cw,ch);
					if(jam){
						//(the brass is below the fill line, so it's always striped)
						DrawImage("HRNSHJF",pos,fl,ia*0.9,scale:tsc,col:color(255,225,60,50));
					}else{
						if(st==2)DrawImage("HRNSHBF",pos,fl,ia,scale:tsc,col:afill);
						DrawImage("HRNSHOF",pos,fl,ia*0.9,scale:tsc,col:aline);
					}
				}
			}

			//side saddle shells: 2 columns of 6, bottom-up, left column first
			if(type==RN_IT_SADDLE){
				double bs=sc*RN_SADDLESCALE;
				double bw=7*bs,bh=4.5*bs;
				vector2 bsc=(bs,bs)*0.25;
				for(int k=0;k<12;k++){
					vector2 bp=(x+(k/6)*bw,bottom-bh*((k%6)+1));
					if(k<ex){
						DrawImage("HRNBOXF",bp,fl,ia,scale:bsc,col:afill);
						DrawImage("HRNBOXO",bp,fl,ia*0.9,scale:bsc,col:aline);
					}else DrawImage("HRNBOXO",bp,fl,ia*0.3,scale:bsc);
				}
			}

			//stacked boxes, bottom-up (Vulcanette's queued mags),
			//with the battery shrunk to the column's width on top
			if(type==RN_IT_STACK){
				double bh=4.5*sc;
				for(int k=0;k<4;k++){
					vector2 bp=(x,bottom-bh*(k+1));
					if(ex&(1<<k)){
						DrawImage("HRNBOXF",bp,fl,ia,scale:tsc,col:afill);
						DrawImage("HRNBOXO",bp,fl,ia*0.9,scale:tsc,col:aline);
					}else DrawImage("HRNBOXO",bp,fl,ia*0.3,scale:tsc);
				}
				double cs=sc*0.5;		//cell texture is 14x22 units -> 7 wide
				double cw=14*cs,chh=RN_STACKCELLH*sc;
				vector2 cp=(x,bottom-bh*4-1*sc-chh);
				double bfrac=rn_itfrac[i];
				if(bfrac<0)DrawImage("HRNMGDO",cp,fl,ia*0.3,scale:(cs,cs)*0.25);
				else RN_DrawFilledShape("HRNMGD",cp,cs,cw,chh,bfrac,ia,sflags);
			}

			//number above
			int num=rn_itnum[i];
			if(num>=0){
				string tx=FormatNumber(num);
				double tws=NewSmallFont.StringWidth(tx);
				double tsz=tws>0?min(0.42,(w+gap*sc*0.8)/tws):0.42;
				drawstring(
					pnewsmallfont,tx,
					(x+w*0.5,labely-NewSmallFont.GetHeight()*tsz-1),
					sflags|DI_TEXT_ALIGN_CENTER,
					rn_itnumcol[i],ia*0.9,scale:(tsz,tsz)
				);
				labely-=NewSmallFont.GetHeight()*tsz+1;
			}

			//BFG harness label
			if(ex&RN_EX_HARNESS)drawstring(
				pnewsmallfont,StringTable.Localize("$HDRN_HARNESS"),
				(x,labely-NewSmallFont.GetHeight()*0.4-1),
				sflags|DI_TEXT_ALIGN_LEFT,
				Font.CR_GOLD,ia*0.9,scale:(0.4,0.4)
			);

			x+=w;
		}
	}

	// ------------------------------------------------------------
	// What's loaded in the gun (family 1: mag-fed weapons)
	// returns: known, rounds in mag (-1 = no mag), mag capacity,
	//          chamber (0 empty, 1 spent, 2 live), dirty (ZM66 refilled mag)
	// ------------------------------------------------------------
	bool,int,int,int,bool RN_LoadedMag(hdweapon w){
		if(!w)return false,0,0,0,false;
		if(w is "ZM66AssaultRifle"){
			int m=w.weaponstatus[ZM66S_MAG];
			int ch=(w.weaponstatus[0]&ZM66F_CHAMBER)?2:0;
			if(m<0)return true,-1,50,ch,false;
			return true,min(m%100,50),50,ch,m>100;
		}
		if(w is "LiberatorRifle"){
			int m=w.weaponstatus[LIBS_MAG];
			int ch=w.weaponstatus[LIBS_CHAMBER];
			return true,m<0?-1:min(m,30),30,clamp(ch,0,2),false;
		}
		if(w is "HDSMG"){
			int m=w.weaponstatus[SMGS_MAG];
			int ch=w.weaponstatus[SMGS_CHAMBER];
			return true,m<0?-1:min(m,30),30,clamp(ch,0,2),false;
		}
		if(w is "HDPistol"){
			int m=w.weaponstatus[PISS_MAG];
			int ch=w.weaponstatus[PISS_CHAMBER];
			return true,m<0?-1:min(m,15),15,clamp(ch,0,2),false;
		}
		return false,0,0,0,false;
	}
	//current fire mode / weapon mode as a short label ("" = nothing to show)
	string RN_FireMode(hdweapon w){
		if(!w)return "";
		int st=w.weaponstatus[0];
		if(w is "HDPistol"){
			if(!(st&PISF_SELECTFIRE))return "";
			return StringTable.Localize((st&PISF_FIREMODE)?"$HDRN_FM_AUTO":"$HDRN_FM_SEMI");
		}
		if(w is "HDSMG"){
			if(w.weaponstatus[SMGS_SWITCHTYPE]==1)return "";
			int a=w.weaponstatus[SMGS_AUTO];	//0 semi, 1 burst, 2 auto
			return StringTable.Localize(a>=2?"$HDRN_FM_AUTO":a==1?"$HDRN_FM_BURST":"$HDRN_FM_SEMI");
		}
		if(w is "ZM66AssaultRifle"){
			if(st&ZM66F_GLMODE)return StringTable.Localize("$HDRN_FM_GL");
			if(st&ZM66F_NOFIRESELECT)return "";
			int a=w.weaponstatus[ZM66S_AUTO];	//0 semi, 1 auto, 2+ burst
			return StringTable.Localize(a>=2?"$HDRN_FM_BURST":a==1?"$HDRN_FM_AUTO":"$HDRN_FM_SEMI");
		}
		if(w is "LiberatorRifle"){
			if(st&LIBF_GRENADEMODE)return StringTable.Localize("$HDRN_FM_GL");
			if(st&LIBF_NOAUTO)return "";
			return StringTable.Localize((st&LIBF_FULLAUTO)?"$HDRN_FM_AUTO":"$HDRN_FM_SEMI");
		}
		if(w is "Vulcanette")return (st&VULCF_FAST)?"2100 RPM":"700 RPM";
		if(w is "Hunter"){
			if(st&HUNTF_EXPORT)return "";	//pump only
			int fm=w.weaponstatus[HUNTS_FIREMODE];	//0 pump, 1 semi, 2 auto
			return StringTable.Localize(fm>=2?"$HDRN_FM_AUTO":fm==1?"$HDRN_FM_SEMI":"$HDRN_FM_PUMP");
		}
		if(w is "ThunderBuster"){
			return StringTable.Localize((st&TBF_ALT)?"$HDRN_FM_SCATTER":"$HDRN_FM_DETONATOR");
		}
		return "";
	}

	//weapons whose HD readout is fully replaced by the inspect panel
	bool RN_ReplacesReadout(hdweapon w){
		if(!w)return false;
		bool known,dirty;
		int a,b,c;
		[known,a,b,c,dirty]=RN_LoadedMag(w);
		return known
			||w is "Vulcanette"
			||w is "BFG9K"
			||w is "ThunderBuster"
			||w is "Lumberjack"
			||w is "Hunter"
		;
	}


	// ------------------------------------------------------------
	// Compass (top centre): 1 = minimal (sliding letters), 2 = bar with ticks
	// ------------------------------------------------------------
	static const string RN_COMPASSKEYS[]={
		"$HDRN_CMP_N","$HDRN_CMP_NE","$HDRN_CMP_E","$HDRN_CMP_SE",
		"$HDRN_CMP_S","$HDRN_CMP_SW","$HDRN_CMP_W","$HDRN_CMP_NW"
	};
	int RN_CompassStyle(){
		int style=rn_compass?rn_compass.GetInt():2;
		if(style<=0)return 0;
		int when=rn_compasswhen?rn_compasswhen.GetInt():1;
		if(when==2&&hudlevel!=2)return 0;	//only while holding Use
		return style;
	}
	void RN_DrawCompass(){
		int style=RN_CompassStyle();
		if(!style)return;

		//actor angle: 0 = east, 90 = north -> compass heading, clockwise from north.
		//the angle only changes once per tic (35/s), so it's interpolated
		//between the last two tics to move smoothly at any framerate
		double ang=rn_angprev+Actor.deltaangle(rn_angprev,rn_angcur)*rn_ticfrac;
		double heading=90.-ang;
		heading-=floor(heading/360.)*360.;

		int fl=DI_SCREEN_HCENTER|DI_SCREEN_TOP;
		//distance between the points: same width, fewer degrees shown
		//(short 90, medium 60, long 40 degrees each side)
		int zoom=rn_compasszoom?rn_compasszoom.GetInt():0;
		double span=zoom>=2?40.:zoom==1?60.:90.;
		double half=style==1?70.:90.;		//HUD units each side
		double ppd=half/span;
		double liney=16.;					//centre line of the bar

		//faint line across (both styles)
		fill(color(55,255,255,255),-half,liney-0.25,half*2,0.5,fl);

		for(int a=0;a<360;a+=15){
			double dx=a-heading;
			dx-=360.*floor((dx+180.)/360.);
			if(abs(dx)>span)continue;
			double x=dx*ppd;
			double fade=1.-abs(dx)/span;
			if(style==2)fade=sqrt(fade);

			if(!(a%45)){
				bool big=!(a%90);
				double ts=big?0.55:0.42;
				string t=StringTable.Localize(RN_COMPASSKEYS[a/45]);
				//centre the text on its point by hand (scaled width),
				//sitting on a common baseline just above the line
				//(the engine's HUD text adds 1 unscaled unit before every
				//character, so that has to be taken out to really centre it)
				int nch=t.CodePointCount();
				double tw=NewSmallFont.StringWidth(t)*ts;
				double th=NewSmallFont.GetHeight()*ts;
				drawstring(
					pnewsmallfont,t,(x-(tw+nch+1)*0.5,liney-2.5-th),fl|DI_TEXT_ALIGN_LEFT,
					Font.CR_WHITE,fade,scale:(ts,ts)
				);
				if(style==2)fill(color(int(255*fade),235,235,235),x-0.5,liney-1.5,1,3,fl);
			}else if(style==2){
				fill(color(int(170*fade),235,235,235),x-0.6,liney-0.6,1.2,1.2,fl);
			}
		}

		//centre marker, centred on the line
		if(style==1)fill(color(255,235,235,235),-0.5,liney-1.75,1,3.5,fl);
		else fill(color(255,255,210,60),-0.4,liney-2.75,0.8,5.5,fl);
	}

	// ------------------------------------------------------------
	// Full HUD (hold Use) extras: reserve ammo, weapon stash, compass
	// ------------------------------------------------------------
	void RN_DrawFullHudExtras(){
		int mxht=-4-mIndexFont.mFont.GetHeight();
		vector2 hs=GetHUDScale();

		vector2 sm=RN_SafeMargins();
		vector2 so;

		//reserve ammo counters and stashed weapons, bottom right
		vector2 old=RN_AddOffset(-sm.x,-72*hs.y-sm.y);
		drawammocounters(mxht);
		screen.SetOffset(old.x,old.y);
		so=RN_AddOffset(-sm.x,-sm.y);
		drawweaponstash(true,-120);
		screen.SetOffset(so.x,so.y);

		so=RN_AddOffset(0,sm.y);

		//compass and coordinates, top centre
		//(HD-style letters only when our own compass is off;
		//coordinates go below the compass either way)
		bool owncompass=RN_CompassStyle()>0;
		int wephelpheight=NewSmallFont.GetHeight()*(owncompass?4:2);
		double compangle=hpl.angle;
		for(int i=0;i<4;i++){
			if(owncompass)break;
			double compangle2=hpl.deltaangle(RN_COMPANGS[i],compangle);
			if(abs(compangle2)<120)screen.DrawText(NewSmallFont,
				RN_COMPCOLS[i],
				320+compangle2*32/cplayer.fov,
				wephelpheight,
				RN_COMPNAMES[i],
				DTA_VirtualWidth,640,DTA_VirtualHeight,480
			);
		}
		if(!owncompass)screen.DrawText(NewSmallFont,
			font.CR_WHITE,
			320,
			wephelpheight+NewSmallFont.GetHeight(),
			"^",
			DTA_VirtualWidth,640,DTA_VirtualHeight,480
		);
		string postxt=string.format("%i,%i,%i",hpl.pos.x,hpl.pos.y,hpl.pos.z);
		screen.DrawText(NewSmallFont,
			font.CR_DARKGRAY,
			320-(NewSmallFont.StringWidth(postxt)>>1),
			wephelpheight+NewSmallFont.GetHeight()+6,
			postxt,
			DTA_VirtualWidth,640,DTA_VirtualHeight,480
		);
		screen.SetOffset(so.x,so.y);

		//weapon help text, top left
		so=RN_AddOffset(sm.x,sm.y);
		string s=hpl.wephelptext;
		if(s!="")screen.DrawText(NewSmallFont,OptionMenuSettings.mFontColorValue,
			8,
			NewSmallFont.GetHeight()*5,
			s,
			DTA_VirtualWidth,640,
			DTA_VirtualHeight,480,
			DTA_Alpha,0.8
		);
		screen.SetOffset(so.x,so.y);
	}
}
