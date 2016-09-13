require File.expand_path('../../spec_helper.rb', __FILE__)

describe ::OMTK::Loadout::InfantryManager, '#get_quantified_item' do

  it 'should parse the quantified items' do
    expect(subject.get_quantified_item('Some_grenade_class')).to eq [1,0,'Some_grenade_class']
    expect(subject.get_quantified_item('2x Some_grenade_class')).to eq [2,0,'Some_grenade_class']
    expect(subject.get_quantified_item('3x 30#Some_Magazine_class')).to eq [3,30,'Some_Magazine_class']
    expect(subject.get_quantified_item('30#Some_Magazine_class')).to eq [1,30,'Some_Magazine_class']
  end

end


describe ::OMTK::Loadout::InfantryManager, '#sanitize_array' do

  let(:arr) {
    ['Item_class1','Item_class2', '10#Item_class3', 'Item_class2', '10#Item_class3', '3x Item_class3']
  }

  it 'should sanitize the items by removing duplicated entries for a given class, and cumulate quantities' do
    expect(subject.sanitize_array(arr)).to eq ['Item_class1','2x Item_class2', '2x 10#Item_class3', '3x Item_class3'].sort
  end

end

describe ::OMTK::Loadout::InfantryManager, '#merge_loadouts' do

  let(:defaultGear) {
    {
        key1: 'val1',
        key2: 'val22',
        key4: 'val4',
        arr1: ['Item1_class', '2x Item2_class', '2x 30#Item3_class', '2x 50#Item3_class'],
        hash1: {
            hkey1: 'hval11',
            harr: ['Item2_class', '2x 5#Item_class'],
            hash2: {
                hhkey1: 'hhval1',
            }
        }
    }
  }

  let(:classGear) {
    {
        key1: 'val1',
        key2: 'val2',
        key3: 'val3',
        arr1: ['Item4_class', '2x Item2_class', '2x 30#Item3_class'],
        hash1: {
            hkey1: 'hval1',
            harr: ['10x 5#Item_class', '20x 5#Item_class'],
            hash2: {
                hhkey2: 'hhval2',
                hhkey3: 'hhval3',
            }
        },
        hash2: {
            skey1: 'sval1',
            skey2: 'sval2'
        }
    }
  }


  it 'should merge whole examples' do
    res = subject.merge_loadouts(defaultGear, classGear)

    expect(res[:key1]).to eq 'val1'
    expect(res[:key2]).to eq 'val2'
    expect(res[:key3]).to eq 'val3'
    expect(res[:key4]).to eq 'val4'
    expect(res[:arr1].sort).to eq ['2x 50#Item3_class', '4x 30#Item3_class', '4x Item2_class', 'Item1_class', 'Item4_class'].sort
    expect(res[:hash1][:hkey1]).to eq 'hval1'
    expect(res[:hash1][:harr]).to eq ['Item2_class', '32x 5#Item_class'].sort
    expect(res[:hash1][:hash2][:hhkey1]).to eq 'hhval1'
    expect(res[:hash1][:hash2][:hhkey2]).to eq 'hhval2'
    expect(res[:hash1][:hash2][:hhkey3]).to eq 'hhval3'
    expect(res[:hash2][:skey1]).to eq 'sval1'
    expect(res[:hash2][:skey2]).to eq 'sval2'
  end

end