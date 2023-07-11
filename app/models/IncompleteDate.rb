require 'date'

class IncompleteDate
    
    attr_reader :date, :accurate

    def initialize( params = {} )
        if params[:str]
            year, month, day = params[:str].split('-').map(&:to_i)
            str = '111' # precisión día, mes y año
            if day.nil? || day == 0
                day = 15
                str[0] = '0'
            end
            if month.nil? || month == 0 || month > 12
                month = 7
                str[1] = '0'
            end
            if year.nil? || year == 0
                year = 1
                str[2] = '0'
            end
            @accurate = str.to_i(2) # convierte de cadena a binario, 9.to_s(2) pasa a binario
            if @accurate == 1
                day = 1
            end
            @date = Date.new(year,month,day)
        elsif params[:date] && params[:accurate]
            @date = params[:date]
            @accurate = ( params[:accurate].nil? ? 0 : params[:accurate] )
        elsif params[:accurate] && params[:accurate] == 0  # caso ha fallecido pero no se sabe cuando o ha nacido pero no se sabe cuando
            @date = Date.new(1900,1,1)
            @accurate = 0
        else
            @date = Date.new(1900,1,1)
            @accurate = 0
        end
    end

    def digito(n,base,pos)
        # devuelve el dígito en la posicion pos (empezando por la derecha) de n que está en base
        # posición 1 de 6 (110) en base 2 es 0
        # en excel es =COCIENTE(RESIDUO($K$1;K2^K3);K2^(K3-1))
        ( n % ( base ** pos ) ) / ( base ** ( pos - 1 ) )
    end

    def day?
        digito(accurate,2,3) == 1
    end

    def month?
        digito(accurate,2,2) == 1
    end

    def year?
        !accurate.nil? && digito(accurate,2,1) == 1
    end

    def year
        date.year
    end

    def month
        @date.month
    end

    def day
        @date.day
    end

    def to_s
        if date.nil? || accurate.nil? || accurate == 0
            res = ''
        else
            res = ( day? ? date.day.to_s : '??' ) + '/' +
                ( month? ? date.month.to_s : '??' ) + '/' +
                ( year? ? date.year.to_s : '????' )

            if not day?
                if not month?
                    if year?
                        res = "#{date.year}"
                    end
                else
                    if year?
                        res = "#{date.month}/#{date.year}"
                    else
                        res = "#{date.month}/????"
                    end
                end
            end
        end
        return res
    end      

    def edad( reference = IncompleteDate.new( date:Time.now.utc.to_date,accurate:7 ) )
        now = reference.date
        now.year - @date.year - ((now.month > @date.month || (now.month == @date.month && now.day >= @date.day)) ? 0 : 1)
    end

    def difDates( reference = IncompleteDate.new( date:Time.now.utc.to_date,accurate:7 ) )
        result = {}
        if @accurate == 7 and reference.accurate == 7
            result["años"] = reference.year - @date.year - ((reference.month > @date.month || (reference.month == @date.month && reference.day >= @date.day)) ? 0 : 1)
            result["diasTotal"] = ( reference.date - @date ).to_i
        end
        return result
    end

    def hasta(otra)
        result = {}
        if @accurate == 7 and otra.accurate == 7
            result[:years] = otra.year - @date.year - ((otra.month > @date.month || (otra.month == @date.month && otra.day >= @date.day)) ? 0 : 1)
            result[:months] = otra.month - @date.month
            if result[:month] < 0
                result[:month] + 12
            end
            result[:totalDays] = ( otra.date - @date ).to_i
        end
        return result
    end

    def -(otra)
        result = ( self.date - otra.date ).to_i
        return result
    end

    def to(otra = IncompleteDate.new( date:DateTime.now.to_date,accurate:7 ))
        result = {}
        if year? and otra.year?
            result[:years] = otra.year - @date.year
        end
        if month? and otra.month?
            result[:months] = otra.month - @date.month
            if result[:months] < 0 and result[:years] and result[:years] > 0
                result[:months] += 12
                if year? and otra.year?
                    result[:years] -= 1
                end
            end
        end
        if day? and otra.day?
            result[:days] = otra.day - @date.day
            if result[:days] < 0 and result[:months] and result[:months] > 0
                result[:days] += Date.new(@date.year, @date.month, -1).day
                if month? and otra.month?
                    result[:months] -= 1
                end
            end
        end
        result[:totalDays] = ( otra.date - @date ).to_i

        if month? and day? and otra.month? and otra.day?
            result[:sameDay] = ( result[:months] == 0 and result[:days] == 0 )

            result[:nextSameDay] = Date.new(otra.year,@date.month,@date.day)
            if result[:nextSameDay] - DateTime.now.to_date < 0
                result[:nextSameDay] = Date.new(otra.year+1,@date.month,@date.day)
            end

            result[:days2sameDay] = (result[:nextSameDay] - DateTime.now.to_date).to_i
        end

        if result[:years]
            if result[:years] > 0
                result[:str] = "#{result[:years]} #{result[:years] > 1 ? 'años' : 'año'}"
            elsif result[:years] == 0
                if result[:months]
                    if result[:months] > 0
                        result[:str] = "#{result[:months]} #{result[:months] > 1 ? 'meses' : 'mes'}"
                    elsif result[:months] == 0
                        if result[:days]
                            if result[:days] > 0
                                result[:str] = "#{result[:days]} #{result[:days] > 1 ? 'dias' : 'día'}"
                            elsif result[:days] == 0
                                result[:str] = "mismo día"
                            end
                        else
                            result[:str] = "días"
                        end
                    end
                else
                    result[:str] = "meses"
                end
            end
        end
        return result
    end

    def toStr(otra = IncompleteDate.new( date:DateTime.now.to_date,accurate:7 ))
        result = to(otra)[:str]
        if not result
            result = ''
        end
        return result
    end

end
