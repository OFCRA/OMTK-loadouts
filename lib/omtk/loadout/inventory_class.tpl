class Inventory
{
    class primaryWeapon
	{
		name="rhs_weap_ak74m_gp25";
		optics="rhs_acc_pgo7v";
		muzzle="rhs_acc_dtk";
		class primaryMuzzleMag
		{
			name="rhs_30Rnd_545x39_AK";
			ammoLeft=30;
		};
	};
	class secondaryWeapon
	{
		name="rhs_weap_rpg7";
		optics="rhs_acc_pgo7v";
	};
	class handgun
	{
		name="rhs_weap_makarov_pm";
		class primaryMuzzleMag
		{
			name="rhs_mag_9x18_8_57N181S";
			ammoLeft=8;
		};
	};
	class binocular
	{
		name="lerca_1200_black";
	};
	class uniform
	{
		typeName="rhs_uniform_gorka_r_g";
		isBackpack=0;
		class MagazineCargo
		{
			items=3;
			class Item0
			{
				name="SmokeShell";
				count=1;
				ammoLeft=1;
			};
			class Item1
			{
				name="Chemlight_green";
				count=1;
				ammoLeft=1;
			};
			class Item2
			{
				name="rhs_30Rnd_545x39_AK";
				count=2;
				ammoLeft=30;
			};
		};
		class ItemCargo
		{
	    	items=1;
		    class Item0
			{
			    name="FirstAidKit";
				count=1;
			};
		};
	};
	class vest
	{
	    typeName="rhs_6b23_vydra_3m";
		isBackpack=0;
		class MagazineCargo
		{
			items=4;
			class Item0
			{
		    	name="SmokeShellGreen";
				count=1;
				ammoLeft=1;
			};
			class Item1
			{
			    name="Chemlight_green";
				count=1;
				ammoLeft=1;
			};
			class Item2
			{
				name="rhs_30Rnd_545x39_AK";
				count=1;
				ammoLeft=30;
			};
			class Item3
			{
			    name="rhs_mag_9x18_8_57N181S";
				count=3;
				ammoLeft=8;
			};
		};
	};
	class backpack
	{
	    typeName="rhs_assault_umbts";
		isBackpack=1;
	};
	map="ItemMap";
	compass="ItemCompass";
	watch="ItemWatch";
	radio="tf_anprc152";
	goggles="rhs_balaclava";
	headgear="rhs_6b7_1m_olive";
};