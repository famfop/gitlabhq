# frozen_string_literal: true

module Gitlab
  module ImportExport
    class FileImporter
      include Gitlab::ImportExport::CommandLineUtil

      ImporterError = Class.new(StandardError)

      MAX_RETRIES = 8

      def self.import(*args, **kwargs)
        new(*args, **kwargs).import
      end

      def initialize(importable:, archive_file:, shared:)
        @importable = importable
        @archive_file = archive_file
        @shared = shared
      end

      def import
        mkdir_p(@shared.export_path)
        mkdir_p(@shared.archive_path)

        clean_extraction_dir!(@shared.export_path)
        copy_archive

        wait_for_archived_file do
          validate_decompressed_archive_size if Feature.enabled?(:validate_import_decompressed_archive_size)
          decompress_archive
        end
      rescue StandardError => e
        @shared.error(e)
        false
      ensure
        remove_import_file
        clean_extraction_dir!(@shared.export_path)
      end

      private

      # Exponentially sleep until I/O finishes copying the file
      def wait_for_archived_file
        MAX_RETRIES.times do |retry_number|
          break if File.exist?(@archive_file)

          sleep(2**retry_number)
        end

        yield
      end

      def decompress_archive
        result = untar_zxf(archive: @archive_file, dir: @shared.export_path)

        raise ImporterError, "Unable to decompress #{@archive_file} into #{@shared.export_path}" unless result

        result
      end

      def copy_archive
        return if @archive_file

        @archive_file = File.join(@shared.archive_path, Gitlab::ImportExport.export_filename(exportable: @importable))

        remote_download_or_download_or_copy_upload
      end

      def remote_download_or_download_or_copy_upload
        import_export_upload = @importable.import_export_upload

        if import_export_upload.remote_import_url.present?
          download(
            import_export_upload.remote_import_url,
            @archive_file,
            size_limit: ::Import::GitlabProjects::RemoteFileValidator::FILE_SIZE_LIMIT
          )
        else
          download_or_copy_upload(
            import_export_upload.import_file,
            @archive_file,
            size_limit: ::Import::GitlabProjects::RemoteFileValidator::FILE_SIZE_LIMIT
          )
        end
      end

      def remove_import_file
        FileUtils.rm_rf(@archive_file)
      end

      def validate_decompressed_archive_size
        raise ImporterError, _('Decompressed archive size validation failed.') unless size_validator.valid?
      end

      def size_validator
        @size_validator ||= DecompressedArchiveSizeValidator.new(archive_path: @archive_file)
      end
    end
  end
end
