rule "FC062", "Cookbook should have version metadata" do
  tags %w{metadata supermarket}
  metadata do |ast, filename|
    [file_match(filename)] unless field(ast, "version").any?
  end
end
