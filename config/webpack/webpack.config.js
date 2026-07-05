const { webpackConfig } = require('shakapacker')
const { merge } = require('webpack-merge')
const webpack = require('webpack')

const customConfig = {
	plugins: [
		new webpack.ProvidePlugin({
			$: 'jquery',
			jQuery: 'jquery',
			Popper: ['popper.js', 'default']
		})
	]
}

module.exports = merge(webpackConfig, customConfig)
