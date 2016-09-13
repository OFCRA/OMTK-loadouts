require File.expand_path('../../spec_helper.rb', __FILE__)

describe Arma3::OMTK::InfantryManager , '#process' do

  let(:sqmFiles) {
    Dir.glob(File.expand_path('../../data/*/*', __FILE__)).map { |x|
      File.join(x, 'mission.sqm')
    }
  }

  it 'should write loadout inside init section' do
    sqmFiles.each { |sqmFile|
      subject.load(
          blue_classes: File.expand_path('../../../data/classes/bluefor.classes.yml', __FILE__),
          red_classes: File.expand_path('../../../data/classes/redfor.classes.yml', __FILE__),
          blue_gears: File.expand_path('../../../data/infantry/ocp.yml', __FILE__),
          blue_weapons: File.expand_path('../../../data/weapons/us_backfire.yml', __FILE__),
          red_gears: File.expand_path('../../../data/infantry/emr.yml', __FILE__),
          red_weapons: File.expand_path('../../../data/weapons/ru_backfire.yml', __FILE__)
      )
      mission = ::Arma3::Sqm::MissionManager.load_mission(sqmFile)
      expect {
        jjson = mission.to_json
        mJson = subject.generate(jjson)
        sqm = ::Arma3::Sqm::Generator.generate(mJson)
        genFilePath = File.join(File.dirname(sqmFile), 'mission.mdf.sqm')
        File.open(genFilePath, 'w+') { |f|
          f.puts sqm #JSON::pretty_generate jjson  #sqm
        }
      }.to_not raise_exception
    }
  end
end


describe Arma3::OMTK::InfantryManager , '#get_MTK_class' do

  let(:sqmFiles) {
    Dir.glob(File.expand_path('../../data/*', __FILE__)).map { |x|
      File.join(x, 'sqm.sqm')
    }
  }

  it 'should return the right OMTK Class name' do
    sqmFiles.each { |sqmFile|
      subject.load(
          blue_classes: File.expand_path('../../../data/classes/bluefor.classes.yml', __FILE__),
          red_classes: File.expand_path('../../../data/classes/redfor.classes.yml', __FILE__),
          blue_gears: File.expand_path('../../../data/infantry/marpat_wood.yml', __FILE__),
          blue_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__),
          red_gears: File.expand_path('../../../data/infantry/2rgt_ru_emr.yml', __FILE__),
          red_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__)
      )

      expect(subject.send(:get_MTK_class,
                          'B_G_officer_F',
                          'WEST')).to eq({cdc: {'classes' => ['B_officer_F', 'B_G_officer_F'], 'description'=> 'Chef de Camp', 'rank' => 'COLONEL'}})
      expect(subject.send(:get_MTK_class,
                          'O_Soldier_AR_F',
                          'EAST')).to eq({autorifleman: {'classes' => ['O_Soldier_AR_F'], 'description' => 'Fusilier-Automatique'}})
    }
  end
end


describe Arma3::OMTK::InfantryManager, '#add_quantified_item' do

  it 'should parse quantified items' do
    expect(subject.send(:add_quantified_item,
                        'addItemToUniform',
                        '3x ACE_fieldDressing')).to eq('[this,3,"ACE_fieldDressing"] call omtk_fnc_addItemToUniform;')
    expect(subject.send(:add_quantified_item,
                        'addItemToVest',
                        'ACE_fieldDressing')).to eq('[this,1,"ACE_fieldDressing"] call omtk_fnc_addItemToVest;')
    expect(subject.send(:add_quantified_item,
                        'addItem',
                        'ACE_fieldDressing')).to eq('[this,1,"ACE_fieldDressing"] call omtk_fnc_addItem;')

  end
end


describe Arma3::OMTK::InfantryManager , '#remove_all' do

  it 'should parse remove all items' do
    expect(subject.send(:remove_all)).to eq("removeAllWeapons this;\nremoveAllItems this;\nremoveAllAssignedItems this;\nremoveUniform this;\nremoveVest this;\nremoveBackpackGlobal this;\nremoveHeadgear this;\nremoveGoggles this;")
  end
end

describe Arma3::OMTK::InfantryManager , '#addGears' do

  it 'should add infantry to CdC' do
    subject.load(
        blue_classes: File.expand_path('../../../data/classes/bluefor.classes.yml', __FILE__),
        red_classes: File.expand_path('../../../data/classes/redfor.classes.yml', __FILE__),
        blue_gears: File.expand_path('../../../data/infantry/2rgt_us_marpat_wood.yml', __FILE__),
        blue_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__),
        red_gears: File.expand_path('../../../data/infantry/ru_flora.yml', __FILE__),
        red_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__)
    )

    expect(subject.send(:add_gears, 'cdc', 'WEST')).to eq('this forceAddUniform "rhs_uniform_FROG01_wd";this addVest "rhsusf_spc";this addHeadgear "rhsusf_mich_helmet_marpatwd_norotos_arc";this addBackpack "tf_rt1523g_rhs";')
    expect(subject.send(:add_gears, 'recon', 'WEST')).to eq('this forceAddUniform "rhs_uniform_FROG01_wd";this addVest "rhsusf_spc";this addHeadgear "rhs_Booniehat_marpatwd";this setFace "WhiteHead_22_a";')
    expect(subject.send(:add_gears, 'marksman', 'WEST')).to eq('this forceAddUniform "rhs_uniform_FROG01_wd";this addVest "rhsusf_spc";this addHeadgear "rhs_Booniehat_marpatwd";this setFace "WhiteHead_22_a";')
  end
end

describe Arma3::OMTK::InfantryManager , '#addWeapons' do

  it 'should add infantry' do
    subject.load(
        blue_classes: File.expand_path('../../../data/classes/bluefor.classes.yml', __FILE__),
        red_classes: File.expand_path('../../../data/classes/redfor.classes.yml', __FILE__),
        blue_gears: File.expand_path('../../../data/infantry/2rgt_us_marpat_wood.yml', __FILE__),
        blue_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__),
        red_gears: File.expand_path('../../../data/infantry/2rgt_ru_emr.yml', __FILE__),
        red_weapons: File.expand_path('../../../data/weapons/2rgt_us_usarmy.yml', __FILE__)
    )

    expect(subject.send(:add_weapons, 'cdc', 'WEST')).to eq('[this,1,"rhs_mag_30Rnd_556x45_M855A1_Stanag"] call omtk_fnc_addItem;this addWeapon "rhs_weap_m4a1_grip";this addPrimaryWeaponItem "rhsusf_acc_ACOG3";[this,1,"rhsusf_mag_7x45acp_MHP"] call omtk_fnc_addItem;this addWeapon "rhsusf_weap_m1911a1";this addWeapon "Binocular";[this,6,"ACE_fieldDressing"] call omtk_fnc_addItem;[this,2,"ACE_morphine"] call omtk_fnc_addItem;[this,2,"rhs_mag_m67"] call omtk_fnc_addItem;[this,2,"SmokeShell"] call omtk_fnc_addItem;[this,1,"ACE_EarPlugs"] call omtk_fnc_addItem;this linkItem "ItemMap";this linkItem "ItemCompass";this linkItem "ItemRadio";this linkItem "tf_microdagr";[this,9,"rhs_mag_30Rnd_556x45_M855A1_Stanag"] call omtk_fnc_addItem;[this,2,"rhsusf_mag_7x45acp_MHP"] call omtk_fnc_addItem;[this,4,"rhs_mag_m67"] call omtk_fnc_addItem;[this,4,"SmokeShell"] call omtk_fnc_addItem;[this,1,"ACE_MapTools"] call omtk_fnc_addItem;[this,1,"ACE_microDAGR"] call omtk_fnc_addItem;')
    expect(subject.send(:add_weapons, 'recon', 'WEST')).to eq('[this,1,"rhs_mag_30Rnd_556x45_M855A1_Stanag"] call omtk_fnc_addItem;this addWeapon "rhs_weap_m4a1_grip";this addPrimaryWeaponItem "rhsusf_acc_ACOG3";this addWeapon "ACE_Yardage450";[this,6,"ACE_fieldDressing"] call omtk_fnc_addItem;[this,2,"ACE_morphine"] call omtk_fnc_addItem;[this,2,"rhs_mag_m67"] call omtk_fnc_addItem;[this,2,"SmokeShell"] call omtk_fnc_addItem;[this,1,"ACE_EarPlugs"] call omtk_fnc_addItem;this linkItem "ItemMap";this linkItem "ItemCompass";this linkItem "ItemRadio";this linkItem "tf_microdagr";[this,9,"rhs_mag_30Rnd_556x45_M855A1_Stanag"] call omtk_fnc_addItem;[this,4,"rhs_mag_m67"] call omtk_fnc_addItem;[this,4,"SmokeShell"] call omtk_fnc_addItem;[this,1,"ACE_MapTools"] call omtk_fnc_addItem;[this,1,"ACE_microDAGR"] call omtk_fnc_addItem;')
  end
end
