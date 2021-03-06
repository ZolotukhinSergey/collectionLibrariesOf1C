
#Область ПрограммныйИнтерфейс

// Отправляет в Sentry отчет об завершившихся аварийно фоновых заданиях
//
//Параметры:
//	- ЗаписьЖурналаРЗ - Структура - Информация о фоновом задании завершившимся с ошибкой
//
Функция ОтправитьЛогПоФоновомуЗаданию(ЗаписьЖурналаРЗ) Экспорт
	
	Если Не КодОбщегоНазначения.ПроверитьВключенаЛиДополнительнаяНастройкаПрограммы("Отправка лога в Sentry") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		Сообщение = СформироватьСообщение(?(ЗаписьЖурналаРЗ.Свойство("ИнформацияОбОшибке"),
			ЗаписьЖурналаРЗ.ИнформацияОбОшибке, Неопределено),, ЗаписьЖурналаРЗ);
		Сообщение["tags"].Вставить("event", "BackgroundJob");
		Попытка
			id = Число(ЗаписьЖурналаРЗ.Ключ);
		Исключение
			id = 0;
		КонецПопытки;
		Возврат ОтправитьСообщение(Сообщение, id);
	Исключение
		Возврат Ложь;
	КонецПопытки;
	
КонецФункции

// Отправляет в Sentry отчет об не успешном завершении обращения к нашему API
//
//Параметры:
//	- ПараметрыМетода - Структура - Информация о запросе и ответе API
//	- Ответ - HTTPСервисОтвет - Ответ на запрос к нашему сервису
//
Функция ОтправитьЛогПоНашемуAPI(ПараметрыМетода, Ответ) Экспорт
	
	Если Не КодОбщегоНазначения.ПроверитьВключенаЛиДополнительнаяНастройкаПрограммы("Отправка лога в Sentry") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		Сообщение = СформироватьСообщение(, ?(Ответ.КодСостояния >= 500 И Ответ.КодСостояния <= 599, "error", "warning"),,
			СтрШаблон("При обращении к %1 возвращается код состояния %2 и телом %3",
			ПараметрыМетода.ИмяТекущегоМетода, Ответ.КодСостояния, ПараметрыМетода.ОтветТело), Ложь, ПараметрыМетода.ИмяТекущегоМетода);
		Сообщение["extra"].Вставить("nameAPI", ПараметрыМетода.ИмяТекущегоМетода);
		Сообщение["extra"].Вставить("requestId", ПараметрыМетода.ИдентификаторСообщения);
		Сообщение["extra"].Вставить("idMessage", ПараметрыМетода.id);
		//Сообщение["extra"].Вставить("bodyIn", ПараметрыМетода.Тело);
		//Сообщение["extra"].Вставить("bodyIn", ПараметрыМетода.ДанныеТела);
		//Попытка
		//	Если СтрНайти("{[", Лев(ПараметрыМетода.ОтветТело, 1)) > 0 Тогда
		//		Сообщение["extra"].Вставить("bodyOut",
		//			ОбменСообщениямиССервисами.ПрочитатьJSONвДанные(ПараметрыМетода.ОтветТело,, Истина));
		//	Иначе
		//		Сообщение["extra"].Вставить("bodyOut", ПараметрыМетода.ОтветТело);
		//	КонецЕсли;
		//Исключение
		//	Сообщение["extra"].Вставить("bodyOut", ПараметрыМетода.ОтветТело);
		//КонецПопытки;
		Сообщение["extra"].Вставить("statusCode", Ответ.КодСостояния);
		Сообщение["extra"].Вставить("HTTPМетод", ПараметрыМетода.HTTPМетод);
		Сообщение["extra"].Вставить("headers", ПараметрыМетода.Заголовки);
		Сообщение["extra"].Вставить("queryParameter", ПараметрыМетода.ПараметрыЗапроса);
		Сообщение["extra"].Вставить("dateIn", Формат(ПараметрыМетода.ДатаСобытияВхода, "Л=ru_RU; ДЛФ=DT"));
		Сообщение["extra"].Вставить("dateOut", Формат(ПараметрыМетода.ДатаСобытияВыхода, "Л=ru_RU; ДЛФ=DT"));
		Сообщение["extra"].Вставить("duration", КодОбщегоНазначения.ПолучитьВремяВыполнения(
			ПараметрыМетода.ВремяСобытияВхода, ПараметрыМетода.ВремяСобытияВыхода));
		Сообщение["tags"].Вставить("event", "internalAPI");
		Возврат ОтправитьСообщение(Сообщение, ПараметрыМетода.id);
	Исключение
		Возврат Ложь;
	КонецПопытки;
	
КонецФункции

// Отправляет в Sentry отчет об не успешном завершении обращения к внешнему API
//
//Параметры:
//	- ПараметрыМетода - Структура - Информация о запросе и ответе API
//	- Ответ - HTTPСервисОтвет - Ответ на запрос к нашему сервису
//
Функция ОтправитьЛогПоВнешнемуAPI(ПараметрыИсхСообщения, ПараметрыВхСообщения, Ответ) Экспорт
	
	Если Не КодОбщегоНазначения.ПроверитьВключенаЛиДополнительнаяНастройкаПрограммы("Отправка лога в Sentry") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		ИмяМетода = Строка(ПараметрыИсхСообщения.Метод);
		Сообщение = СформироватьСообщение(, ?(Ответ.КодСостояния >= 500 И Ответ.КодСостояния <= 599, "error", "warning"),,
			СтрШаблон("При обращении к %1 возвращается код состояния %2 и телом %3",
			ИмяМетода, Ответ.КодСостояния, ПараметрыВхСообщения.Тело), Ложь, ИмяМетода);
		Сообщение["extra"].Вставить("nameAPI", ИмяМетода);
		Сообщение["extra"].Вставить("addressResource", ПараметрыИсхСообщения.АдресРесурса);
		Сообщение["extra"].Вставить("requestId", ПараметрыИсхСообщения.ИдентификаторСообщения);
		Сообщение["extra"].Вставить("idMessage", ПараметрыИсхСообщения.id);
		//Попытка
		//	Если СтрНайти("{[", Лев(ПараметрыВхСообщения.Тело, 1)) > 0 Тогда
		//		Сообщение["extra"].Вставить("bodyIn",
		//			ОбменСообщениямиССервисами.ПрочитатьJSONвДанные(ПараметрыВхСообщения.Тело,, Истина));
		//	Иначе
		//		Сообщение["extra"].Вставить("bodyIn", ПараметрыВхСообщения.Тело);
		//	КонецЕсли;
		//Исключение
		//	Сообщение["extra"].Вставить("bodyIn", ПараметрыВхСообщения.Тело);
		//КонецПопытки;
		//Попытка
		//	Если СтрНайти("{[", Лев(ПараметрыИсхСообщения.Тело, 1)) > 0 Тогда
		//		Сообщение["extra"].Вставить("bodyOut",
		//			ОбменСообщениямиССервисами.ПрочитатьJSONвДанные(ПараметрыИсхСообщения.Тело,, Истина));
		//	Иначе
		//		Сообщение["extra"].Вставить("bodyOut", ПараметрыИсхСообщения.Тело);
		//	КонецЕсли;
		//Исключение
		//	Сообщение["extra"].Вставить("bodyOut", ПараметрыИсхСообщения.Тело);
		//КонецПопытки;
		Сообщение["extra"].Вставить("statusCode", Ответ.КодСостояния);
		Сообщение["extra"].Вставить("HTTPМетод", ПараметрыИсхСообщения.HTTPМетод);
		//Сообщение["extra"].Вставить("headersIn", ПараметрыВхСообщения.Заголовки);
		//Сообщение["extra"].Вставить("headersOut", ПараметрыИсхСообщения.Заголовки);
		//Сообщение["extra"].Вставить("parametersIn", ПараметрыВхСообщения.Параметры);
		//Сообщение["extra"].Вставить("parametersOut", ПараметрыИсхСообщения.Параметры);
		Сообщение["extra"].Вставить("dateIn", Формат(ПараметрыВхСообщения.ДатаСобытия, "Л=ru_RU; ДЛФ=DT"));
		Сообщение["extra"].Вставить("dateOut", Формат(ПараметрыИсхСообщения.ДатаСобытия, "Л=ru_RU; ДЛФ=DT"));
		Сообщение["extra"].Вставить("duration", КодОбщегоНазначения.ПолучитьВремяВыполнения(
			ПараметрыИсхСообщения.ВремяСобытия, ПараметрыВхСообщения.ВремяСобытия));
		Сообщение["tags"].Вставить("event", "externalAPI");
		Возврат ОтправитьСообщение(Сообщение, ПараметрыИсхСообщения.id);
	Исключение
		Возврат Ложь;
	КонецПопытки;
	
КонецФункции

// Отправляет в Sentry отчет об исключительной ситуации в коде
//
//Параметры:
//	- ЗаписьЖурналаРЗ - Структура - Информация о фоновом задании завершившимся с ошибкой
//
Функция ОтправитьЛогПоИсключению(ИнформацияОбОшибке = Неопределено, УровеньЛога = "error", id = 0,
	ИмяМетодаГдеОшибка = "", ТипОшибки = "runtime", ОсновноеСообщение = "") Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	Если Не КодОбщегоНазначения.ПроверитьВключенаЛиДополнительнаяНастройкаПрограммы("Отправка лога в Sentry") Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Попытка
		Сообщение = СформироватьСообщение(ИнформацияОбОшибке, УровеньЛога,,,, ТипОшибки, ИмяМетодаГдеОшибка, ОсновноеСообщение);
		Сообщение["tags"].Вставить("event", "exception");
		Возврат ОтправитьСообщение(Сообщение, id);
	Исключение
		Возврат Ложь;
	КонецПопытки;
	
КонецФункции

#КонецОбласти

#Область СлужебныйПрограммныйИнтерфейс

// Формирует сообщение для Sentry
// Параметры:
//	- УровеньЛога - Строка - "error" или "warning"
//
Функция СформироватьСообщение(ИнформацияОбОшибке = Неопределено, УровеньЛога = "error",
	ЗаписьЖурналаРЗ = Неопределено, ТекстИсключения = "", ПолучатьИсториюПользователя = Истина,
	ТипОшибки = "runtime", ИмяМетодаГдеОшибка = "", ОсновноеСообщение = "")
	
	Если ИнформацияОбОшибке = Неопределено Тогда
		ИнформацияОбОшибке = ИнформацияОбОшибке();
	КонецЕсли;
	
	Если ПустаяСтрока(ИнформацияОбОшибке.ИсходнаяСтрока) Тогда
		Попытка
			Если ТекстИсключения = "" Тогда
				Если ЗаписьЖурналаРЗ = Неопределено Тогда
					ВызватьИсключение "Искуственное исключение";
				Иначе
					ВызватьИсключение СтрШаблон("ФЗ %1 (%2) завершилось аварийно",
						ЗаписьЖурналаРЗ.Наименование, ЗаписьЖурналаРЗ.ИмяМетода);
				КонецЕсли;
			Иначе
				ВызватьИсключение ТекстИсключения;
			КонецЕсли;
		Исключение
			ИнформацияОбОшибке = ИнформацияОбОшибке();
		КонецПопытки;
	КонецЕсли;
	
	СисИнфо = Новый СистемнаяИнформация;
	Если ЗаписьЖурналаРЗ = Неопределено Тогда
		ТекущийСеанс = ПолучитьТекущийСеансИнформационнойБазы();
	КонецЕсли;
	СтрокаСоединения = СтрокаСоединенияИнформационнойБазы();
	
	Тело = Новый Соответствие;
	Тело.Вставить("platform", "1C");
	Тело.Вставить("modules", Новый Соответствие);
	Тело.Вставить("extra", Новый Соответствие);
	Тело.Вставить("exception", ДобавитьИнформациюОбИсключении(ИнформацияОбОшибке, ТипОшибки, ИмяМетодаГдеОшибка));
	Тело.Вставить("contexts", Новый Соответствие);
	Тело.Вставить("tags", Новый Соответствие);
	Если КодОбщегоНазначенияКлиентСерверПовтИсп.ЭтоРабочаяБаза() Тогда
		Тело.Вставить("environment", "production");
	ИначеЕсли КодОбщегоНазначенияКлиентСерверПовтИсп.ЭтоТестоваяБаза() Тогда
		Тело.Вставить("environment", "test");
	Иначе
		Тело.Вставить("environment", "dev");
	КонецЕсли;
	Тело.Вставить("user", Новый Соответствие);
	Тело.Вставить("release", Метаданные.Версия);
	Тело.Вставить("message", ?(ОсновноеСообщение = "",
		"", ОсновноеСообщение + Символы.ПС) + ПодробноеПредставлениеОшибки(ИнформацияОбОшибке));
	Тело.Вставить("level", УровеньЛога);
	
	#Область ИнформацияОПользователе
	
	Если ЗаписьЖурналаРЗ = Неопределено Тогда
		Если ТекущийСеанс.Пользователь = Неопределено Тогда
			СвойстваПользователя = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(ПараметрыСеанса.ТекущийПользователь,
				"Код, Наименование, ИдентификаторПользователяИБ");
			Тело["user"].Вставить("username", СвойстваПользователя.Код);
			Тело["user"].Вставить("fullName", СвойстваПользователя.Наименование);
			Тело["user"].Вставить("uid", Строка(СвойстваПользователя.ИдентификаторПользователяИБ));
		Иначе
			Тело["user"].Вставить("username", ТекущийСеанс.Пользователь.Имя);
			Тело["user"].Вставить("fullName", ТекущийСеанс.Пользователь.ПолноеИмя);
			Тело["user"].Вставить("uid", Строка(ТекущийСеанс.Пользователь.УникальныйИдентификатор));
			Тело["user"].Вставить("os", ТекущийСеанс.Пользователь.ПользовательОС);
		КонецЕсли;
		Тело["user"].Вставить("clientId", Строка(СисИнфо.ИдентификаторКлиента));
	Иначе
		СвойстваПользователя = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(ЗаписьЖурналаРЗ.Пользователь,
			"Код, Наименование, ИдентификаторПользователяИБ");
		Тело["user"].Вставить("username", СвойстваПользователя.Код);
		Тело["user"].Вставить("fullName", СвойстваПользователя.Наименование);
		Тело["user"].Вставить("uid", Строка(СвойстваПользователя.ИдентификаторПользователяИБ));
	КонецЕсли;
	
	#КонецОбласти
	
	#Область Контекст
	
	#Область Платформа1С
	
	Тело["contexts"].Вставить("platform", Новый Соответствие);
	Тело["contexts"]["platform"].Вставить("type", "platform");
	Тело["contexts"]["platform"].Вставить("name", "1С:Enterprise 8.3");
	Тело["contexts"]["platform"].Вставить("version", СисИнфо.ВерсияПриложения);
	Тело["contexts"]["platform"].Вставить("raw_description", "1С:Enterprise 8.3");
	
	#КонецОбласти
	
	#Область Конфигурация1С
	
	Тело["contexts"].Вставить("app", Новый Соответствие);
	Тело["contexts"]["app"].Вставить("type", "runtime");
	Тело["contexts"]["app"].Вставить("name", Метаданные.Имя);
	Тело["contexts"]["app"].Вставить("version", Метаданные.Версия);
	Тело["contexts"]["app"].Вставить("raw_description", Метаданные.Имя);
	
	#КонецОбласти
	
	#Область ОперационнаяСистема
	
	Тело["contexts"].Вставить("os", Новый Соответствие);
	Тело["contexts"]["os"].Вставить("type", "os");
	Тело["contexts"]["os"].Вставить("name", Строка(СисИнфо.ТипПлатформы));
	Тело["contexts"]["os"].Вставить("version", СисИнфо.ВерсияОС);
	Тело["contexts"]["os"].Вставить("raw_description", Строка(СисИнфо.ТипПлатформы));
	
	#КонецОбласти
	
	#КонецОбласти
	
	Тело["tags"].Вставить("platform", СисИнфо.ВерсияПриложения);
	
	#Область СтрокаПодключенияК_ИБ
	
	Тело["tags"].Вставить("ConnectionString", СтрокаСоединения);
	Тело["extra"].Вставить("ConnectionString", СтрокаСоединения);
	
	Если СтрНайти(СтрокаСоединения, "Srvr=") <> 0 Тогда
		//СтрокаСоединения = СтрЗаменить(СтрокаСоединения, ";", "");
		СтрокаСоединения = СтрЗаменить(СтрокаСоединения, """", "");
		СтрокаСоединения = СтрЗаменить(СтрокаСоединения, "Srvr=", "");
		СтрокаСоединения = СтрЗаменить(СтрокаСоединения, "Ref=", "");
		мСтрокиСоединения = СтрРазделить(СтрокаСоединения, ";", Ложь);
		Тело["extra"].Вставить("serverBase", мСтрокиСоединения[0]);
		Тело["extra"].Вставить("nameBase", мСтрокиСоединения[1]);
	КонецЕсли;
	
	#КонецОбласти
	
	#Область ДопИнформация
	
	Если ЗаписьЖурналаРЗ = Неопределено Тогда
		Тело.Вставить("timestamp", ДатуВTimestamp());
		Тело.Вставить("breadcrumbs", ДобавитьИсториюСобытийПользователя(ТекущийСеанс.НачалоСеанса, ПолучатьИсториюПользователя));
		
		ФЗ = ТекущийСеанс.ПолучитьФоновоеЗадание();
		
		Тело["extra"].Вставить("hostNameSession", ТекущийСеанс.ИмяКомпьютера);
		Тело["extra"].Вставить("hostName", ИмяКомпьютера());
		Тело["extra"].Вставить("appName", ТекущийСеанс.ИмяПриложения);
		Тело["extra"].Вставить("appFullName", ПредставлениеПриложения(ТекущийСеанс.ИмяПриложения));
		Тело["extra"].Вставить("beginSession", Формат(ТекущийСеанс.НачалоСеанса, "Л=ru_RU; ДЛФ=DT"));
		Тело["extra"].Вставить("numberSession", ТекущийСеанс.НомерСеанса);
		Тело["extra"].Вставить("numberConnection", ТекущийСеанс.НомерСоединения);
		Тело["extra"].Вставить("isThread", ФЗ <> Неопределено);
		Тело["extra"].Вставить("dateEvent", Формат(ТекущаяДатаСеанса(), "Л=ru_RU; ДЛФ=DT"));
		Тело["extra"].Вставить("userMessage", КодОбщегоНазначения.ПолучитьТекстомСообщенияПользователю());
		Если ФЗ <> Неопределено Тогда
			Тело["extra"].Вставить("nameModuleBackgroundJob", ФЗ.ИмяМетода);
		КонецЕсли;
	Иначе
		Тело.Вставить("timestamp", ДатуВTimestamp(ЗаписьЖурналаРЗ.Конец));
		Тело.Вставить("breadcrumbs", ДобавитьИсториюСобытийПользователя(ЗаписьЖурналаРЗ.Начало, Ложь));
		
		Тело["extra"].Вставить("hostName", ЗаписьЖурналаРЗ.Сервер);
		ИмяПриложения = "BackgroundJob";
		Тело["extra"].Вставить("appName", ИмяПриложения);
		Тело["extra"].Вставить("appFullName", ПредставлениеПриложения(ИмяПриложения));
		Тело["extra"].Вставить("beginSession", Формат(ЗаписьЖурналаРЗ.Начало, "Л=ru_RU; ДЛФ=DT"));
		Тело["extra"].Вставить("endSession", Формат(ЗаписьЖурналаРЗ.Конец, "Л=ru_RU; ДЛФ=DT"));
		Тело["extra"].Вставить("numberSession", ЗаписьЖурналаРЗ.НомерСеанса);
		//Тело["extra"].Вставить("numberConnection", ТекущийСеанс.НомерСоединения);
		Тело["extra"].Вставить("isThread", Истина);
		Тело["extra"].Вставить("dateEvent", Формат(ЗаписьЖурналаРЗ.Конец, "Л=ru_RU; ДЛФ=DT"));
		Тело["extra"].Вставить("userMessage", ЗаписьЖурналаРЗ.Сообщения);
		Тело["extra"].Вставить("idJob", ЗаписьЖурналаРЗ.ИдентификаторЗадания);
		Тело["extra"].Вставить("nameJob", ЗаписьЖурналаРЗ.Наименование);
		Тело["extra"].Вставить("keyJob", ЗаписьЖурналаРЗ.Ключ);
		
		Тело["extra"].Вставить("duration", ОбщегоНазначения.ПолучитьДлительность(
			ЗаписьЖурналаРЗ.Конец - ЗаписьЖурналаРЗ.Начало));
		
		//РеквизитыЗадания = ОбщегоНазначения.ЗначенияРеквизитовОбъекта(ЗаписьЖурналаРЗ.Задание, "ИмяМетода, Регламентное");
		Тело["extra"].Вставить("nameModule", ЗаписьЖурналаРЗ.ИмяМетода);
		Тело["extra"].Вставить("regulation", ЗаписьЖурналаРЗ.Регламентное);
	КонецЕсли;
	
	РазмерСтроки = 30 * 1024; // из размера 2 байта на символ, 60КБ
	Если СтрДлина(Тело["extra"]["userMessage"]) > РазмерСтроки Тогда
		Тело["extra"]["userMessage"] = Прав(Тело["extra"]["userMessage"], РазмерСтроки);
	КонецЕсли;
	
	#КонецОбласти
	
	Возврат Тело;
	
КонецФункции

Функция ДобавитьИнформациюОбИсключении(ИнформацияОбОшибки, ТипОшибки = "runtime", ИмяМетодаГдеОшибка = "")
	
	Результат = Новый Соответствие;
	Результат.Вставить("values", Новый Массив);
	Результат["values"].Добавить(Новый Соответствие);
	ПервыйЭлемент = Результат["values"][Результат["values"].ВГраница()];
	ПервыйЭлемент.Вставить("module", ИнформацияОбОшибки.ИмяМодуля);
	ПервыйЭлемент.Вставить("value", ИнформацияОбОшибки.Описание);
	ПервыйЭлемент.Вставить("type", ТипОшибки);
	ПервыйЭлемент.Вставить("stacktrace", Новый Соответствие);
	
	СтрокаСтека = ПодробноеПредставлениеОшибки(ИнформацияОбОшибки);
	
	Позиция = СтрНайти(СтрокаСтека, "по причине:" + Символы.ПС);
	Если Позиция <> 0 Тогда
		СтрокаСтека = Лев(СтрокаСтека, Позиция - 1);
	КонецЕсли;
	
	мСтека = Новый Массив;
	мСтрокСтека = СтрРазделить(СтрокаСтека, Символы.ПС, Ложь);
	//Для Инд = 2 По мСтрокСтека.ВГраница() Цикл
	Инд = мСтрокСтека.ВГраница();
	Пока Инд >= 2 Цикл
		мПоСтрокеСтека = СтрРазделить(мСтрокСтека[Инд], ":");
		СимволСкобки = СтрНайти(мПоСтрокеСтека[0], "(");
		СтрокаНомераСтроки = Сред(мПоСтрокеСтека[0], СимволСкобки + 1);
		СтрокаНомераСтроки = СтрЗаменить(СтрокаНомераСтроки, ")", "");
		СтрокаНомераСтроки = СтрЗаменить(СтрокаНомераСтроки, "}", "");
		Попытка
			НомерСтроки = Число(СтрокаНомераСтроки);
		Исключение
			НомерСтроки = 0;
		КонецПопытки;
		ИмяМодуля = СтрЗаменить(Лев(мПоСтрокеСтека[0], СимволСкобки - 1), "{", "");
		ИсходнаяСтрока = СокрЛП(мПоСтрокеСтека[1]);
		
		Стек = Новый Соответствие;
		Стек.Вставить("module", ИмяМодуля);
		Стек.Вставить("lineno", НомерСтроки);
		Стек.Вставить("context_line", ИсходнаяСтрока);
		Стек.Вставить("function", "");
		мСтека.Добавить(Стек);
		
		Инд = Инд - 1;
	КонецЦикла;
	
	Стек = Новый Соответствие;
	Стек.Вставить("module", ИнформацияОбОшибки.ИмяМодуля);
	Стек.Вставить("lineno", ИнформацияОбОшибки.НомерСтроки);
	Стек.Вставить("context_line", ИнформацияОбОшибки.ИсходнаяСтрока);
	Стек.Вставить("function", ИмяМетодаГдеОшибка);
	мСтека.Добавить(Стек);
	
	Инд = мСтека.ВГраница();
	Пока Инд >= 1 Цикл
	//Для Инд = 0 По мСтека.ВГраница() - 1 Цикл
		Если ПустаяСтрока(мСтека[Инд]["function"]) Тогда
			мСтека[Инд]["function"] = мСтека[Инд - 1]["context_line"];
		КонецЕсли;
		Инд = Инд - 1;
	КонецЦикла;
	
	Если ПустаяСтрока(мСтека[0]["function"]) Тогда
		мСтека[0]["function"] = "unknown";
	КонецЕсли;
	ПервыйЭлемент["stacktrace"].Вставить("frames", мСтека);
	
	Возврат Результат;
	
КонецФункции

Функция ДобавитьИсториюСобытийПользователя(ДатаНачалаСеанса, ДобавитьИсторию = Истина, ОграничитьКоличеством = 10)
	
	мИстории = Новый Массив;
	
	Если ДобавитьИсторию Тогда
		мПромежуточный = Новый Массив;
		ИсторияПользователя = ИсторияРаботыПользователя.Получить();
		Для Каждого ЭлементИстории Из ИсторияПользователя Цикл
			Если ЭлементИстории.Дата < ДатаНачалаСеанса И мПромежуточный.Количество() >= ОграничитьКоличеством Тогда
				Прервать;
			КонецЕсли;
			НоваяИстория = Новый Соответствие;
			//НоваяИстория.Вставить("date", Формат(ЭлементИстории.Дата, "Л=ru_RU; ДЛФ=DT"));
			//НоваяИстория.Вставить("URL", ЭлементИстории.НавигационнаяСсылка);
			НоваяИстория.Вставить("type", "ui");
			НоваяИстория.Вставить("category", "ui.dialog");
			НоваяИстория.Вставить("message", ЭлементИстории.НавигационнаяСсылка);
			//НоваяИстория.Вставить("timestamp", Формат(ЭлементИстории.Дата, "Л=ru_RU; ДЛФ=DT"));
			НоваяИстория.Вставить("timestamp", ДатуВTimestamp(ЭлементИстории.Дата));
			//мИстории.Добавить(НоваяИстория);
			мПромежуточный.Добавить(НоваяИстория);
		КонецЦикла;
		Инд = мПромежуточный.ВГраница();
		Пока Инд >= 0 Цикл
			мИстории.Добавить(мПромежуточный[Инд]);
			Инд = Инд - 1;
		КонецЦикла;
	КонецЕсли;
	
	Результат = Новый Соответствие;
	Результат.Вставить("values", мИстории);
	
	Возврат Результат;
	
КонецФункции

Функция ОтправитьСообщение(Сообщение, id = 0)
	
	Заголовки = Новый Соответствие;
	Заголовки.Вставить("Content-Type", "JSON");
	
	СтрТело = ОбменСообщениямиССервисами.ПреобразоватьДанныеВ_JSON(Сообщение, Истина);
	
	ClientKey = "caa566d525484f068aa6986a50c2e2ee";
	//ClientKey = "b19c4a788eba11ea83110242ac130012";
	
	Ответ = ОбменСообщениямиССервисами.ОтправитьЗапросHTTP("sentry.webbankir.team",
		//СтрШаблон("/api/store/?sentry_version=5&sentry_key=%1", ClientKey),
		СтрШаблон("/api/15/store/?sentry_key=%1", ClientKey),
		Заголовки, "sentry", СтрТело, 10, Истина,,,,,,,,,, Истина,,, id,,, Ложь);
	
	Возврат Ответ.КодСостояния >= 200 И Ответ.КодСостояния <= 299;
	
КонецФункции

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

Функция ДатуВTimestamp(ДатаСобытия = Неопределено)
	
	Возврат УниверсальноеВремя(?(ДатаСобытия = Неопределено, ТекущаяДатаСеанса(), ДатаСобытия)) - '19700101';
	
КонецФункции

#КонецОбласти
