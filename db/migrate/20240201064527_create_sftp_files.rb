class CreateSftpFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :sftp_files do |t|
      t.string :name
      t.string :object_key
      t.string :s3_file_url
      t.timestamps
    end
  end
end
