// ------------------------------------------------------------
// Tactical HUD v1.1.0 - tactical-shooter style HUD for Hideous Destructor
//
// - Paper doll (bottom left) filled from the bottom up according
//   to health, tinted white -> yellow -> orange -> red.
//   Lost maximum health grows from the top down in dark red with
//   darker diagonal stripes.
// - ECG / heart rate next to the paper doll.
// - Ammo panel in the bottom right (hdrn_ammopanel.zs); weapons it doesn't
//   handle keep HD's own readout, above the BPM.
// - Inventory / items in the top right (can be disabled).
// ------------------------------------------------------------
class HDRNStatusBar:HDStatusBar{

	//cached cvars
	transient cvar rn_enable;
	transient cvar rn_inspectreq;
	transient cvar rn_inspecthold;
	transient cvar rn_showonpump;
	transient cvar rn_ammocolor;
	transient cvar rn_ammousepcol;
	transient cvar rn_compass;
	transient cvar rn_compasswhen;
	transient cvar rn_compasselastic;
	transient cvar rn_compasszoom;
	transient cvar rn_inspectonreload;
	transient cvar rn_dollscale;
	transient cvar rn_showecg;
	transient cvar rn_showhpnum;
	transient cvar rn_inventory;
	transient cvar rn_showitems;
	transient cvar rn_armourstyle;
	transient cvar rn_armournum;
	transient cvar rn_armourwidth;
	transient cvar rn_safex;
	transient cvar rn_safey;
	transient cvar rn_safeaspect;

	enum HDRNConsts{
		RN_ECGN=64,			//samples kept for the ECG trace (1 per tic)
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
		rn_ammocolor=CVar.FindCVar("hdrn_ammocolor");
		rn_ammousepcol=CVar.FindCVar("hdrn_ammousepcol");
		rn_compass=CVar.FindCVar("hdrn_compass");
		rn_compasswhen=CVar.FindCVar("hdrn_compasswhen");
		rn_compasselastic=CVar.FindCVar("hdrn_compasselastic");
		rn_compasszoom=CVar.FindCVar("hdrn_compasszoom");
		rn_inspectonreload=CVar.FindCVar("hdrn_inspectonreload");
		rn_dollscale=CVar.FindCVar("hdrn_dollscale");
		rn_showecg=CVar.FindCVar("hdrn_showecg");
		rn_showhpnum=CVar.FindCVar("hdrn_showhpnumber");
		rn_inventory=CVar.FindCVar("hdrn_inventory");
		rn_showitems=CVar.FindCVar("hdrn_showitems");
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
		if(inspecttimer>RN_PFADE&&!rn_inspectweaponly)return;
		inspecttimer=max(inspecttimer,len);
		rn_inspectweaponly=true;
	}

	//lock the inspected ammo to the weapon held when the key was pressed,
	//so switching weapons doesn't change what's being shown
	void RN_StartInspect(int len){
		inspecttimer=len;
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
		int inspectlength=RN_T_INSPECT;
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

		//flash the fire mode label when it changes (not when switching weapons)
		let fmw=hdweapon(cplayer.readyweapon);
		string fmnow=RN_FireMode(fmw);
		if(fmw==rn_lastmodewep&&fmnow!=rn_lastmode)rn_modeflash=35;
		rn_lastmode=fmnow;
		rn_lastmodewep=fmw;
		if(rn_modeflash>0)rn_modeflash--;

		//new ammo panel visibility
		RN_PanelTick();

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

		RN_DrawWeaponReadout();
		RN_DrawTopRight();

		//ammo panel, bottom right (replaces the old bottom-centre panel)
		so=RN_AddOffset(-sm.x,-sm.y);
		RN_DrawAmmoPanel();
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
		//only while hudlevel==1; hide it, the ammo panel does that job now
		int oldhudlevel=hudlevel;
		if(!menuwep&&hudlevel==1)hudlevel=0;

		vector2 sm=RN_SafeMargins();
		if(RN_ReplacesReadout(hdw)){
			//nothing: this weapon's ammo is shown by the ammo panel
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

	void RN_DrawWeaponReadout(){
		let w=cplayer.readyweapon;
		if(!w||w==WP_NOCHANGE)return;
		let hdw=hdweapon(w);

		RN_DrawWeaponStatusShifted(w);

		vector2 sm=RN_SafeMargins();
		vector2 so;
		//weapon sprite (bottom right, above the inventory)
		so=RN_AddOffset(-sm.x,-sm.y);
		if(
			hudlevel==2
			||cvar.getcvar("hd_hudsprite",cplayer).getbool()
			||!cvar.getcvar("r_drawplayersprites",cplayer).getbool()
		)drawselectedweapon(-8,-40,DI_SCREEN_RIGHT_BOTTOM|DI_ITEM_RIGHT_BOTTOM);
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
			//shifted from the bottom centre to the top right corner
			int mxht=-4-mIndexFont.mFont.GetHeight();
			vector2 old=RN_AddOffset(sw*0.5-52*hs.x-sm.x,-(sh-44*hs.y)+sm.y);
			DrawSurroundingInv(25,-4,42,mxht,DI_SCREEN_CENTER_BOTTOM,0);
			DrawInvSel(25,-14,42,mxht,DI_SCREEN_CENTER_BOTTOM);
			screen.SetOffset(old.x,old.y);
			y=46;
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
	// Ammo colour (used by the ammo panel)
	// ------------------------------------------------------------
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

	//weapons whose HD readout is fully replaced by the ammo panel
	//(hand grenades keep HD's readout: it has the throw indicator)
	bool RN_ReplacesReadout(hdweapon w){
		return RN_PanelWeapon(w)&&!(w is "HDGrenadeThrower");
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
