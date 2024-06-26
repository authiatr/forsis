require 'nokogiri'

module Fastlane
  module Helper
    module ForsisHelper
      class Generator
        def self.generate(junit_report_path, sonarqube_report_path, search_in_target_folder)
          junit_file = Nokogiri::XML(File.open(junit_report_path))
          sonarqube_file = File.open("#{sonarqube_report_path}/Test_sonarqube_report.xml", 'w')
          test_suites = junit_file.xpath("//testsuite")
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.testExecutions({ version: :'1' }) do
              test_suites.each do |test_file|
                file_name = `echo #{test_file["name"]}| cut -d'.' -f 2`.gsub(/\n/, '')

                if search_in_target_folder then
                  file_target = `echo #{test_file["name"]}| cut -d'.' -f 1`.gsub(/\n/, '')
                  file_path = get_test_file_path(file_name, file_target)
                else 
                  file_path = get_test_file_path(file_name, ".")
                end

                test_cases = []
                test_file.children.each do |child|
                  test_cases << child if child.instance_of?(Nokogiri::XML::Element)
                end
                xml.file({ path: :"#{file_path}" }) do
                  test_cases.each do |test|
                    test_duration = (test["time"].to_f * 1000).round
                    test_failures = []
                    test.children.each do |test_child|
                      test_failures << test_child if test_child.instance_of?(Nokogiri::XML::Element)
                    end
                    xml.testCase({ name: :"#{test["name"]}", duration: :"#{test_duration}" }) do
                      test_failures.each do |failure|
                        failure_type = failure.name
                        failure_message = failure["message"]
                        failure_description = failure.text
                        xml.send(failure_type, failure_description, message: failure_message)
                      end
                    end
                  end
                end
              end
            end
          end
          sonarqube_file.puts(builder.to_xml)
          sonarqube_file.close
        end

        def self.get_test_file_path(file_name, directory)
          `find #{directory} -iname "#{file_name}.swift"`.gsub(/\n/, '')
        end
      end

      def self.show_message
        UI.message("Hello from the forsis plugin helper!")
      end
    end
  end
end
