package grinder

import grails.converters.JSON
import org.codehaus.groovy.grails.commons.DefaultGrailsDomainClass
import org.springframework.http.MediaType
import org.springframework.mock.web.MockHttpServletRequest
import spock.lang.Specification

class BeanPathToolsSpec extends Specification {

    def "Can get property value for a basic class"() {
        setup:
        def obj = new TestClazzA(
                foo: '1111',
                bar: -12.52,
                baz: null
        )
        expect:
        exp == BeanPathTools.getNestedValue(obj, path)
        where:
        exp         | path
        '1111'      | 'foo'
        -12.52      | 'bar'
        null        | 'baz'
    }

    def "Can get property value for a class hierarchy"() {
        setup:
        def obj = new TestClazzB(
                left: new TestClazzA(
                        foo: '1'
                ),
                right: new TestClazzB(
                        left: new TestClazzB(
                                value: 2
                        ),
                        right: new TestClazzA(
                                foo: '3',
                                bar: 4
                        )
                ),
                value: 5
        )
        expect:
        exp == BeanPathTools.getNestedValue(obj, path)
        where:
        exp         | path
        5           | 'value'
        '1'         | 'left.foo'
        2           | 'right.left.value'
        4           | 'right.right.bar'
    }

    def "Get properties by path"() {
        setup:
        def obj = new TestClazzB(
                left: new TestClazzA(
                        foo: '1'
                ),
                right: new TestClazzB(
                        left: new TestClazzB(
                                value: 2
                        ),
                        right: new TestClazzA(
                                foo: '3',
                                bar: 4,
                                id: 5
                        ),
                        id: 6
                ),
                value: 7,
                id: 8
        )
        expect:
        Map act = [:]
        null == BeanPathTools.propsToMap(obj, path, act)
        exp == act
        where:
        path                    | exp
        'value'                 | [value: 7]
        'left.foo'              | [left: [foo: '1']]
        'right.left.value'      | [right: [left: [value: 2]]]
        'right.right.bar'       | [right: [right: [bar: 4]]]
        'right.right.*'         | [right: [right: [bar: 4, foo: '3', id: 5]]]
        'right.*'               | [right: [id: 6, value: 0]]
    }

    def "Property returns list of domains"() {
        setup:
        def obj = new TestClazzC(
                id: 9,
                value: 10
        )
        expect:
        Map act = [:]
        null == BeanPathTools.propsToMap(obj, path, act)
        exp == act
        where:
        path                    | exp
        'value'                 | [value: 10]
        'fooValues.*'           | [fooValues: [[id: 1, bar: null, foo: 'val 1'], [id: 2, bar: null, foo: 'val 2']]]
    }

	def "Editeddate and created dates are ignored"() {
		setup:
		MockHttpServletRequest request = new MockHttpServletRequest()
		request.addHeader('Accept', 'application/json')
		request.method = 'POST'
		request.requestURI = '/some/url'
		request.contentType = MediaType.APPLICATION_JSON
		when:
		def result = BeanPathTools.flattenMap(request,  [id:9, value:10,editedDate: new Date() + 1, createdDate: new Date()])
		then:
		result.editedDate == null
		result.createdDate == null
		result.id == "9"
		result.value == "10"

	}


    class TestClazzA {
        Long id
        Long version

        String foo
        BigDecimal bar
        List<String> baz

        def getDomainClass() {
            new DefaultGrailsDomainClass(TestClazzA)
        }
    }

    class TestClazzB {
        Long id
        Long version

        def left
        def right
        int value

        def getDomainClass() {
            new DefaultGrailsDomainClass(TestClazzB)
        }
    }

    class TestClazzC {
        Long id
        Long version

        int value

        List getFooValues() {
            [
                    new TestClazzA(id: 1, version: 0, foo: 'val 1'),
                    new TestClazzA(id: 2, version: 0, foo: 'val 2')
            ]
        }

        def getDomainClass() {
            new DefaultGrailsDomainClass(TestClazzB)
        }
    }

}
