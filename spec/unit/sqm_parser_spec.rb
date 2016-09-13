require File.expand_path('../../spec_helper.rb', __FILE__)

describe ::Arma3::Sqm::Parser, '#parse' do

  let(:sqmFiles) {
    Dir.glob(File.expand_path('../../data/*/*', __FILE__)).map { |x|
      File.join(x, 'mission.sqm')
    }
  }

  it 'should parse an existing complex sqm file' do
    sqmFiles.each { |sqmFile|
      raise Exception.new "Mission '#{sqmFile}' sqm file is not available" unless File.exist?(sqmFile)
      expect {
        begin
          puts subject.class.parse(sqmFile).to_json
        rescue Exception => e
          puts "Happens for #{sqmFile}"
          raise e
        end

      }.to_not raise_exception
    }
  end
end

describe ::Arma3::Sqm::Generator, '#generate' do

  let(:sqmFiles) {
    Dir.glob(File.expand_path('../../data/*/*', __FILE__)).map { |x|
      File.join(x, 'mission.sqm')
    }
  }

  it 'should serialize to SQM format' do
    sqmFiles.each { |sqmFile|
      expect {
        json = ::Arma3::Sqm::Parser.parse(sqmFile)
        sqm = subject.class.generate(json)
        genFilePath = File.join(File.dirname(sqmFile), 'mission.gen.sqm')
        File.open(genFilePath, 'w+') { |f|
          f.puts sqm #JSON.pretty_generate(json) #sqm
        }

        src = File.read(sqmFile)
        gen = File.read(genFilePath)
        expect(gen).to eq(src)
      }.to_not raise_exception
    }
     # expect(subject.get_groups(:blue).size).to eq(10)
     # expect(subject.get_groups(:red).size).to eq(8)
     # expect(subject.get_groups(:green).size).to eq(0)
     # expect(subject.get_groups().size).to eq(18)
    # TODO: check for group names

    # expect(subject.get_vehicles).to eq([['Cobra2', 1], ['RHS_NSV_TriPod_MSV', 4], ['UH1H_FFV', 2], ['UH1H_LMG', 4]])
    # expect(subject.get_trigger_zones).to eq(%w'HQ HQ_1 HQ_1_1 HQ_1_1_1 cap_area flag flag_1 med_area obj z z_1 z_2 z_3 z_3_1 z_3_1_1 z_3_1_1_1 z_3_1_1_2')
  end
end