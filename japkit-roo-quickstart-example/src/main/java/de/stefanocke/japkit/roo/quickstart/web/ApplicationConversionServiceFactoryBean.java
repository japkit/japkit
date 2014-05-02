package de.stefanocke.japkit.roo.quickstart.web;

import org.springframework.beans.factory.annotation.Configurable;
import org.springframework.format.FormatterRegistry;
import org.springframework.format.support.FormattingConversionServiceFactoryBean;

@Configurable
/**
 * A central place to register application converters and formatters. 
 */
public class ApplicationConversionServiceFactoryBean extends FormattingConversionServiceFactoryBean {

	@Override
	protected void installFormatters(FormatterRegistry registry) {
		super.installFormatters(registry);
		// Register application converters and formatters
	}

	// public Converter<Timer, String> getTimerToStringConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<de.stefanocke.japkit.roo.quickstart.Timer,
	// java.lang.String>() {
	// public String convert(Timer timer) {
	// return new StringBuilder().append(timer.getMessage()).toString();
	// }
	// };
	// }
	//
	// public Converter<Long, Timer> getIdToTimerConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<java.lang.Long,
	// de.stefanocke.japkit.roo.quickstart.Timer>() {
	// public de.stefanocke.japkit.roo.quickstart.Timer convert(java.lang.Long
	// id) {
	// return Timer.findTimer(id);
	// }
	// };
	// }
	//
	// public Converter<String, Timer> getStringToTimerConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<java.lang.String,
	// de.stefanocke.japkit.roo.quickstart.Timer>() {
	// public de.stefanocke.japkit.roo.quickstart.Timer convert(String id) {
	// return getObject().convert(getObject().convert(id, Long.class),
	// Timer.class);
	// }
	// };
	// }

	public void installLabelConverters(FormatterRegistry registry) {
		// registry.addConverter(getTimerToStringConverter());
		// registry.addConverter(getIdToTimerConverter());
		// registry.addConverter(getStringToTimerConverter());
	}

	public void afterPropertiesSet() {
		super.afterPropertiesSet();
		installLabelConverters(getObject());
	}

	// @Autowired
	// TimerRepository timerRepository;
	//
	// public Converter<TimerWithRepo, String>
	// getTimerWithRepoToStringConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<de.stefanocke.japkit.roo.quickstart.TimerWithRepo,
	// java.lang.String>() {
	// public String convert(TimerWithRepo timerWithRepo) {
	// return "(no displayable fields)";
	// }
	// };
	// }
	//
	// public Converter<Long, TimerWithRepo> getIdToTimerWithRepoConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<java.lang.Long,
	// de.stefanocke.japkit.roo.quickstart.TimerWithRepo>() {
	// public de.stefanocke.japkit.roo.quickstart.TimerWithRepo
	// convert(java.lang.Long id) {
	// return timerRepository.findOne(id);
	// }
	// };
	// }
	//
	// public Converter<String, TimerWithRepo>
	// getStringToTimerWithRepoConverter() {
	// return new
	// org.springframework.core.convert.converter.Converter<java.lang.String,
	// de.stefanocke.japkit.roo.quickstart.TimerWithRepo>() {
	// public de.stefanocke.japkit.roo.quickstart.TimerWithRepo convert(String
	// id) {
	// return getObject().convert(getObject().convert(id, Long.class),
	// TimerWithRepo.class);
	// }
	// };
	// }
}
