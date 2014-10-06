# coding: UTF-8

require 'socket'

# rubocop:disable RescueModifier
internal = !Socket.gethostbyname('repo.release.cerner.corp').nil? rescue false
# rubocop:enable RescueModifier

if internal

  require 'fileutils'
  require 'roll_out/rake_tasks'
  require 'roll_out/site/custom_documentation_renderer'
  require 'roll_out/jira'

  task default: [:clobber, :verify, :site]

  module RollOut
    ## We reconfigure the rake package task so that the tar file contains the version
    ## But the root directory inside the tar file is named only for only the artifact name
    ## This matches the pattern of other cookbooks as distributed through the community site
    module Packaging
      private

      def package_task
        Rake::PackageTask.new(artifact_id, package_version) do |p|
          p.need_tar_gz = true
          p.package_dir = Project::BUILD_DIRECTORY
          p.package_files = package_files

          def p.package_name
            @name
          end

          def p.tar_gz_file
            "#{@name}-#{@version}.tar.gz"
          end
        end
      end
    end

    module Site
      # Add the internal docs to the built site
      class Docs < Section
        def render
          custom_doc_files = []
          FileUtils.chdir('docs') do
            custom_doc_files = Dir['**/*']
          end
          custom_doc_files.each do |custom_doc_file|
            source = File.join('docs', custom_doc_file)
            next unless File.file?(source)
            filename = CustomDocumentationRenderer.convert_filename_to_html(custom_doc_file)
            html = markdown(CustomDocumentationRenderer).render(File.read(source))
            yield filename, StringIO.new(html, 'r')
          end
        end
      end
    end
  end
end
