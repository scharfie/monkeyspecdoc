require 'test/unit'
require 'test/unit/ui/console/testrunner'

def split_shoulda_names(name)
  if /test: (.*) (should .*)\./ =~ name
    [$1, $2]
  elsif /(.*)\(Test(.*)\)/ =~ name
    [$2, $1]
  end
end

module Test
  module Unit

    class Failure
      def filename_and_line
        location[0].to_s.sub(/\A(.+:\d+).*/, '\\1')
      end

      def long_display
        location_display = if(location.size == 1)
          " [#{filename_and_line}]"
        else
          "\n    [#{location.join("\n     ")}]"
        end
        name=(split=split_shoulda_names(@test_name))?split.join(" "):@test_name
        "#{name} FAILED: #{location_display}:\n    #@message"
      end
    end

    class Error
      def filename_and_line
        @exception.backtrace.first.to_s.sub(/\A(.+:\d+).*/, '\\1')
      end

      def long_display
        backtrace = filter_backtrace(@exception.backtrace).join("\n    ")
        name=(split=split_shoulda_names(@test_name))?split.join(" "):@test_name
        "#{@exception.class.name} in #{name}:\n#{message}\n    #{backtrace}"
      end
    end

    module UI
      module Console
        class TestRunner

          alias_method :test_started_old, :test_started

          def test_started(name)
            ctx, should = split_shoulda_names(name)
            unless ctx.nil? or should.nil?
              if ctx != @ctx
                nl
                output("\e[0;34m#{@suite.name}\e[0m\n\e[0;34;1m#{ctx}: \e[0m")
              end
              @ctx = ctx
              @current_test_text = " ==> #{should}"
              #output_single("- #{should}: ")
            else
              test_started_old(name)
            end
          end

          def add_fault(fault)
            @faults << fault
            @already_outputted = true
          end

          def test_finished(name)
            # can cause issues if there's no test text.
            @current_test_text = ' ' if @current_test_text.nil? || @current_test_text.empty?
            if fault = @faults.find {|f| f.test_name == name}
              # Added ! to ERROR for length consistency
              fault_type = fault.is_a?(Test::Unit::Failure) ? "FAILED" : "ERROR!"
              # NOTE -- Concatenation because "\e[0m]" does funky stuff.
              output("[\e[0;31m#{fault_type}\e[0m" + "]#{@current_test_text} (#{@faults.length}) \e[0;31m#{@faults.last.filename_and_line}\e[0m" + '')
            else
              # Added spaces on either side of OK for length consistency
              output("[  \e[0;32mOK\e[0m  ]#{@current_test_text}")
            end
            @already_outputted = false
          end

        end
      end
    end
  end
end

