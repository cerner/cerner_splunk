rule "FC068", "Ensure license is set in metadata" do
  tags %w{metadata supermarket license}
  metadata do |ast, filename|
    [file_match(filename)] unless field(ast, "license").any?
  end
end
