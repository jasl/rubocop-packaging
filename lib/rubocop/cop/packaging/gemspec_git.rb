# frozen_string_literal: true

# Rubocop module
module RuboCop
  # Cop module
  module Cop
    # Packaging module
    module Packaging
      # This cop is used to identify the usage of `git ls-files`
      # and suggests to use a plain Ruby alternative, like `Dir`,
      # `Dir.glob` or `Rake::FileList` instead.
      #
      # @example
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.files = `git ls-files`.split('\n')
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
      #       `git ls-files -z`.split('\\x0').reject { |f| f.match(%r{^(test|spec|features)/}) }
      #     end
      #   end
      #
      #   # bad
      #   Gem::Specification.new do |spec|
      #     spec.files         = `git ls-files`.split('\n')
      #     spec.test_files    = `git ls-files -- test/{functional,unit}/*`.split('\n')
      #     spec.executables   = `git ls-files -- bin/*`.split('\n').map{ |f| File.basename(f) }
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
      #     spec.test_files    = Dir['spec/**/*']
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.files         = Rake::FileList['**/*'].exclude(*File.read('.gitignore').split)
      #   end
      #
      #   # good
      #   Gem::Specification.new do |spec|
      #     spec.files         = Dir.glob('lib/**/*')
      #     spec.test_files    = Dir.glob('test/{functional,test}/*')
      #     spec.executables   = Dir.glob('bin/*').map{ |f| File.basename(f) }
      #   end
      #
      class GemspecGit < Cop
        # This is the message that will be displayed when RuboCop finds an
        # offense of using `git ls-files`.
        MSG = 'Avoid using git to produce lists of files. ' \
          'Downstreams often need to build your package in an environment ' \
          'that does not have git (on purpose). ' \
          'Use some pure Ruby alternative, like `Dir` or `Dir.glob`.'

        def_node_search :xstr, <<~PATTERN
          (block
            (send
              (const
                (const {cbase nil?} :Gem) :Specification) :new)
            (args
              (arg _)) `$(xstr (str #starts_with_git?)))
        PATTERN

        # Extended from the Cop class.
        # More about the `#investigate` method can be found here:
        # https://github.com/rubocop-hq/rubocop/blob/master/lib/rubocop/cop/cop.rb
        #
        # Processing of the AST happens here.
        def investigate(processed_source)
          xstr(processed_source.ast).each do |node|
            add_offense(
              processed_source.ast,
              location: node.loc.expression,
              message: MSG
            )
          end
        end

        # This method is called from inside `#def_node_search`.
        # It is used to find strings which start with 'git'.
        def starts_with_git?(str)
          str.start_with?('git')
        end
      end
    end
  end
end
