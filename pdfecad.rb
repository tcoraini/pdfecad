require 'pdf/reader'

class PdfEcad
     CATEGORIES = {"CA" => "Author", "E" => "Publisher", "V" => "Versionist", "SE" => "SubPublisher"}

	# Inicializa a classe preparando-a para ler o arquivo pdf especficado
	def initialize(file_name)
		PDF::Reader.open(file_name) do |reader|
			full_content = ""
			reader.pages.each do |page|
				full_content = full_content + page.text
			end

			# Essa variável guarda um array com as linhas do arquivo
			@all_lines = full_content.lines
			
			# Removemos as linhas vazias
			@all_lines = @all_lines.delete_if { | line | 
				line.strip.empty?
			}
		end
	end
	 
	def works
		all_works = Array.new
		@all_lines.each do |line|
			# Tenta fazer match com uma linha que descrever obra
			work_info = work(line)
			if (work_info != nil)
				# Se conseguir fazer match com descrição de obra, adiciona
				# no array de obras e prepara um array para receber as
				# descrições dos detentores de direitos autorais
				work_info[:right_holders] = Array.new
				all_works << work_info
			else
				# Não é uma descrição de obra, tenta fazer match com descrição
				# de detentor de direito autoral
				right_holder_info = right_holder(line)
				if (right_holder_info != nil) 
					all_works.last[:right_holders] << right_holder_info
				end
			end
		end
		
		all_works
    end

     def right_holder(line)
		# Expressão regular que identifica linha que descreve detentor de direito autoral
		regex = /^(\d+)\s+((\S+\s)+)\s+((\S+\s)+)\s+([\d\.]+)?\s+((\S+\s)+)\s+(\w+)\s+([\d,]+)\s+([\d\/]+)?\s+(\S+).*/
		matched = regex.match(line)
		
		if ! matched
			nil
		else 
			{
				external_ids: [
					{
						source_name: "Ecad",
						source_id: matched[1].strip
					}
				],
			
				name: matched[2].strip,
				pseudos: [
					{
						name: matched[4].strip,
						main: true
					}
				],
				# Este grupo é opcional na regex, portanto pode ser nil
				ipi: matched[6].nil? ? nil : matched[6].strip.gsub(".", ""),
				society_name: matched[7].strip,
				role: CATEGORIES[matched[9].strip],
				# Transforma string em número
				share: matched[10].gsub(",",".").to_f
			}
		end
     end


    def work(line)
		# Expressão regular que identifica linha que descreve uma obra
		regex = /^(\d+)\s+(T?-[\d\.\s]+-\d?)\s+((\S+\s)+)\s+(\S+)\s+([\d\/]+).*/
		matched = regex.match(line)
		
		if ! matched
			nil
		else 
			{
				external_ids: [
					{
						source_name: "Ecad",
						source_id: matched[1].strip
					}
				],
				iswc: matched[2].strip,
				title: matched[3].strip,
				situation: matched[5].strip,
				created_at: matched[6].strip
			}
		end
    end

end