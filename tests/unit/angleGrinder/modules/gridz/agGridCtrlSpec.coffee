describe "module: angleGrinder.gridz, conroller: AgGridCtrl", ->

  beforeEach module "angleGrinder.gridz", ($provide) ->
    # substitute `flatten` service with a spy
    fakeFlatten = (data) -> data
    $provide.value "flatten", sinon.spy(fakeFlatten)

    return

  ctrl = null
  jqGridEl = null

  before ->
    @gridParams =
      colModel: [{ name: "foo", hidden: true }, { name: "bar", hidden: false }]

  beforeEach inject ($controller) ->
    jqGridEl = sinon.stub($().jqGrid())
    jqGridEl.getGridParam = (name) => @gridParams[name]

    ctrl = $controller "AgGridCtrl"
    ctrl.registerGridElement(jqGridEl)
    sinon.stub(ctrl, "flashOnSuccess")

  describe "#reload", ->

    it "reloads the grid", ->
      # When
      ctrl.reload()

      # Then
      expect(jqGridEl.trigger.called).to.be.true
      expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

    it "returns a promise", inject ($rootScope) ->
      # When
      promise = ctrl.reload()
      $rootScope.$broadcast "gridz:loadComplete", foo: "bar"

      # Then
      resolvedValue = null
      promise.then (data) -> resolvedValue = data

      expect(resolvedValue).to.be.null
      $rootScope.$digest()
      expect(resolvedValue).to.have.property "foo", "bar"

  describe "#getParam", ->
    before -> @gridParams.foo = "bar"

    it "retrieves a particular grid parameter", ->
      expect(ctrl.getParam("foo")).to.eq "bar"

  describe "#setParam", ->
    it "sets a particular grid parameter", ->
      # When
      ctrl.setParam(foo: "bar")

      # Then
      expect(jqGridEl.setGridParam.called).to.be.true
      expect(jqGridEl.setGridParam.calledWith(foo: "bar")).to.be.true

  describe "#updateRow", ->

    context "simple update", ->

      it "updates a row with the given id", ->
        # When
        ctrl.updateRow(123, foo: "bar")

        # Then
        expect(jqGridEl.setRowData.called).to.be.true
        expect(jqGridEl.setRowData.calledWith(123, foo: "bar")).to.be.true

      it "flattens data before inserting it to the grid", inject (flatten) ->
        # When
        ctrl.updateRow(123, foo: bar: "biz")

        # Then
        expect(flatten.called).to.be.true
        expect(flatten.calledWith(foo: bar: "biz")).to.be.true

      it "flashes the updated row", ->
        # Given
        ctrl.updateRow(123, foo: "bar")

        # Then
        expect(ctrl.flashOnSuccess.called).to.be.true
        expect(ctrl.flashOnSuccess.calledWith(123)).to.be.true

    context "when the new data contain empty values", ->
      beforeEach ->
        # stub previous row data
        jqGridEl.getRowData.withArgs(123).returns
          "-row_action_col": "html code for the popup"
          foo: "foo", "bar.baz": "baz", "bar.biz": "biz"

      it "clears the empty values", ->
        # When
        ctrl.updateRow(123, foo: "bar", baz: "baz", bar: {})

        # Then
        expect(jqGridEl.setRowData.called).to.be.true

        args = jqGridEl.setRowData.getCall(0).args
        expect(args[0]).to.eq 123
        expect(args[1]).to.deep.eq foo: "bar", baz: "baz", bar: {}, "bar.baz": null, "bar.biz": null

  describe "#addRow", ->

    describe "when the position is not specified", ->
      it "adds a row at the first position", ->
        # When
        ctrl.addRow(234, foo: "biz")

        # Then
        expect(jqGridEl.addRowData.called).to.be.true
        expect(jqGridEl.addRowData.calledWith(234, foo: "biz", "first")).to.be.true

    describe "when the position is specified", ->
      it "adds a row at the specified position", ->
        # When
        ctrl.addRow(234, foo: "biz", "last")

        # Then
        expect(jqGridEl.addRowData.called).to.be.true
        expect(jqGridEl.addRowData.calledWith(234, foo: "biz", "last")).to.be.true

    it "flattens data before inserting it to the grid", inject (flatten) ->
      # When
      ctrl.addRow(234, foo: bar: "baz")

      # Then
      expect(flatten.called).to.be.true
      expect(flatten.calledWith(foo: bar: "baz")).to.be.true

    it "flashes the inserted row", ->
      # When
      ctrl.addRow(234, foo: "bar")

      # Then
      expect(ctrl.flashOnSuccess.called).to.be.true
      expect(ctrl.flashOnSuccess.calledWith(234)).to.be.true

    it "broadcasts `gridz:rowAdded` event", inject ($rootScope) ->
      # Given
      sinon.spy($rootScope, "$broadcast")

      # When
      ctrl.addRow(234, foo: "bar")
      expect($rootScope.$broadcast.called).to.be.true
      expect($rootScope.$broadcast.calledWith("gridz:rowAdded", 234, foo: "bar")).to.be.true

      # stop spying
      $rootScope.$broadcast.restore()

  describe "#saveRow", ->

    describe "when a row exists in the grid", ->
      beforeEach -> jqGridEl.getInd.returns(true)

      it "updates a row with the given id", ->
        # When
        ctrl.saveRow(123, foo: "bar")

        # Then
        expect(jqGridEl.setRowData.called).to.be.true
        expect(jqGridEl.setRowData.calledWith(123, foo: "bar")).to.be.true

        expect(jqGridEl.addRowData.called).to.be.false

    describe "otherwise", ->
      beforeEach -> jqGridEl.getInd.returns(false)

      it "inserts a new row at the beginning", ->
        # When
        ctrl.saveRow(234, foo: "biz")

        # Then
        expect(jqGridEl.addRowData.called).to.be.true
        expect(jqGridEl.addRowData.calledWith(234, foo: "biz", "first")).to.be.true

        expect(jqGridEl.setRowData.called).to.be.false

  describe "#hasRow", ->

    describe "if a row with the given id exists", ->
      it "returns true", ->
        # Given
        jqGridEl.getInd.returns(id: 123, foo: "bar")

        # When
        expect(ctrl.hasRow(123)).to.be.true

        # Then
        expect(jqGridEl.getInd.called).to.be.true
        expect(jqGridEl.getInd.calledWith(123)).to.be.true

    describe "otherwise", ->
      it "returns false", ->
        # Given
        jqGridEl.getInd.returns(false)

        # When
        expect(ctrl.hasRow(234)).to.be.false

        # Then
        expect(jqGridEl.getInd.called).to.be.true
        expect(jqGridEl.getInd.calledWith(234)).to.be.true

  describe "#getIds", ->
    it "returns an array of the id's in the current grid view", ->
      # Given
      jqGridEl.getDataIDs.returns([1, 2, 3])

      # When
      expect(ctrl.getIds()).to.deep.eq [1, 2, 3]

      # Then
      expect(jqGridEl.getDataIDs.called).to.be.true

  describe "#removeRow", ->
    it "removes a row with the given id", ->
      # Given stub with callback
      ctrl.flashOnSuccess.restore()
      sinon.stub(ctrl, "flashOnSuccess", (id, callback) -> callback())

      # When
      ctrl.removeRow(123)

      # Then
      expect(jqGridEl.delRowData.called).to.be.true
      expect(jqGridEl.delRowData.calledWith(123)).to.be.true

    it "flashes the removed row", ->
      # Given
      ctrl.removeRow(345)

      # Then
      expect(ctrl.flashOnSuccess.called).to.be.true
      expect(ctrl.flashOnSuccess.calledWith(345)).to.be.true

  describe "#search", ->
    it "sets search filters and triggers grid reload", ->
      # When
      ctrl.search(login: "foo")

      # Then
      expect(jqGridEl.setGridParam.called).to.be.true
      expect(jqGridEl.setGridParam.calledWith(search: true, postData: filters: '{"login":"foo"}')).to.be.true

      expect(jqGridEl.trigger.called).to.be.true
      expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

    it "returns a promise", inject ($rootScope) ->
      # Given
      promise = ctrl.search(login: "foo")
      $rootScope.$broadcast "gridz:loadComplete", {}, foo: "bar"

      resolvedValue = null
      promise.then (data) -> resolvedValue = data
      expect(resolvedValue).to.be.null

      # When
      $rootScope.$apply()

      # Then
      expect(resolvedValue).to.not.be.null
      expect(resolvedValue).to.deep.equal login: "foo"

  describe "#getSelectedRowIds", ->
    before -> @gridParams.selarrrow = [1, 2, 3]

    it "returns a list of selected row ids", ->
      expect(ctrl.getSelectedRowIds()).to.deep.eq [1, 2, 3]

  describe "#getRowData", ->

    it "returns a row data for the given id", ->
      # When
      ctrl.getRowData(567)

      # Then
      expect(jqGridEl.getRowData.called).to.be.true
      expect(jqGridEl.getRowData.calledWith(567)).to.be.true

  describe "#addJSONData", ->
    stub = null

    beforeEach inject ($rootScope) ->
      stub = sinon.stub()
      jqGridEl.get.withArgs(0).returns(addJSONData: stub)

      sinon.spy($rootScope, "$broadcast")
      ctrl.addJSONData(page: 1, rows: [{name: "foo"}, {name: "bar"}])

    afterEach inject ($rootScope) ->
      $rootScope.$broadcast.restore()

    it "poulates the grid with the given data", ->
      expect(stub.called).to.be.true

    it "broadcasts `gridz:loadComplete` event", inject ($rootScope) ->
      expect($rootScope.$broadcast.called).to.be.true

  describe "#isColumnHidden", ->

    it "is defined", ->
      expect(ctrl.isColumnHidden).to.not.be.undefined

    describe "when a column with the given id is hidden", ->

      it "returns true", ->
        expect(ctrl.isColumnHidden("foo")).to.be.true

    describe "when a column with the given id is not hidden", ->

      it "returns true", ->
        expect(ctrl.isColumnHidden("bar")).to.be.false

    describe "when a column with is missing", ->

      it "returns undefined", ->
        expect(ctrl.isColumnHidden("fooBar")).to.be.undefined

  describe "#toggleColumn", ->
    it "is defined", ->
      expect(ctrl.toggleColumn).to.not.be.undefined

    describe "when the column is hidden", ->
      beforeEach -> ctrl.toggleColumn("foo")

      it "shows the column", ->
        expect(jqGridEl.jqGrid.called).to.be.true
        expect(jqGridEl.jqGrid.calledWith("showCol", "foo")).to.be.true

      it "resizes the grid", ->
        expect(jqGridEl.trigger.called).to.be.true
        expect(jqGridEl.trigger.calledWith("resize")).to.be.true

    describe "when the column is not hidden", ->
      beforeEach -> ctrl.toggleColumn("bar")

      it "hides the column", ->
        expect(jqGridEl.jqGrid.called).to.be.true
        expect(jqGridEl.jqGrid.calledWith("hideCol", "bar")).to.be.true

      it "resizes the grid", ->
        expect(jqGridEl.trigger.called).to.be.true
        expect(jqGridEl.trigger.calledWith("resize")).to.be.true

  describe "#columnChooser", ->
    it "is defined", ->
      expect(ctrl.columnChooser).to.not.be.undefined

    it "calls `columnChooser` method on the jqGrid", ->
      # When
      ctrl.columnChooser()

      # Then
      expect(jqGridEl.jqGrid.called).to.be.true
      expect(jqGridEl.jqGrid.calledWith("columnChooser")).to.be.true

  describe "pagination", ->

    describe "#getCurrentPage", ->
      before -> @gridParams.page = 2

      it "returns the current page", ->
        expect(ctrl.getCurrentPage()).to.eq 2

    describe "#getTotalRecords", ->
      before -> @gridParams.records = 20

      it "returns the total number of records", ->
        expect(ctrl.getTotalRecords()).to.eq 20

    describe "#getPageSize", ->
      before -> @gridParams.rowNum = 10

      it "returns the total number of records", ->
        expect(ctrl.getPageSize()).to.eq 10

    describe "#getTotalPages", ->
      before ->
        @gridParams.records = 999
        @gridParams.rowNum = 10

      it "return the total number of pages", ->
        expect(ctrl.getTotalPages()).to.eq 100

    describe "#firstPage", ->

      it "loads the first page", ->
        # When
        ctrl.firstPage()

        # Then
        expect(jqGridEl.setGridParam.calledWith(page: 1)).to.be.true
        expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

      it "returns a promise", ->
        promise = ctrl.firstPage()
        expect(promise.then).to.be.a "function"

    describe "#prevPage", ->
      before ->
        @gridParams.records = 999
        @gridParams.rowNum = 10

      context "on the other than the first", ->
        before -> @gridParams.page = 3

        it "loads the previous page", ->
          # When
          ctrl.prevPage()

          # Then
          expect(jqGridEl.setGridParam.calledWith(page: 2)).to.be.true
          expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

        it "returns a promise", ->
          promise = ctrl.prevPage()
          expect(promise.then).to.be.a "function"

      context "on the first page", ->
        before -> @gridParams.page = 1

        it "loads the last page", ->
          # When
          ctrl.prevPage()

          # Then
          expect(jqGridEl.setGridParam.calledWith(page: 100)).to.be.true
          expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

        it "returns a promise", ->
          promise = ctrl.prevPage()
          expect(promise.then).to.be.a "function"

    describe "#nextPage", ->
      before ->
        @gridParams.records = 6
        @gridParams.rowNum = 2

      context "on the page other then the last one", ->
        before -> @gridParams.page = 2

        it "loads the next page", ->
          # When
          ctrl.nextPage()

          # Then
          expect(jqGridEl.setGridParam.calledWith(page: 3)).to.be.true
          expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

        it "returns a promise", ->
          promise = ctrl.nextPage()
          expect(promise.then).to.be.a "function"

      context "on the last page", ->
        before -> @gridParams.page = 3

        it "loads the first page", ->
          # When
          ctrl.nextPage()

          # Then
          expect(jqGridEl.setGridParam.calledWith(page: 1)).to.be.true
          expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

        it "returns a promise", ->
          promise = ctrl.nextPage()
          expect(promise.then).to.be.a "function"

    describe "#lastPage", ->
      before ->
        @gridParams.records = 999
        @gridParams.rowNum = 5

      it "loads the last page", ->
        # When
        ctrl.lastPage()

        # Then
        expect(jqGridEl.setGridParam.calledWith(page: 200)).to.be.true
        expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

      it "returns a promise", ->
        promise = ctrl.lastPage()
        expect(promise.then).to.be.a "function"

    describe "#loadPage", ->

      it "loads the specific page", ->
        # When
        ctrl.loadPage(123)

        # Then
        expect(jqGridEl.setGridParam.calledWith(page: 123)).to.be.true
        expect(jqGridEl.trigger.calledWith("reloadGrid")).to.be.true

      it "returns a promise", inject ($rootScope) ->
        # When
        promise = ctrl.loadPage(123)
        $rootScope.$broadcast "gridz:loadComplete", foo: "bar"

        resolvedValue = null
        promise.then (data) -> resolvedValue = data

        expect(resolvedValue).to.be.null
        $rootScope.$apply()
        expect(resolvedValue).to.have.property "foo", "bar"
