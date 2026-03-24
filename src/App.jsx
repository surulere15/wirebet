import Hero from './components/Hero'
import WhyWirebet from './components/WhyWirebet'
import WhyThisAsset from './components/WhyThisAsset'
import StrategicFit from './components/StrategicFit'
import Contact from './components/Contact'
import Footer from './components/Footer'

function App() {
  return (
    <main className="bg-background min-h-screen selection:bg-white selection:text-black">
      <Hero />
      <WhyWirebet />
      <WhyThisAsset />
      <StrategicFit />
      <Contact />
      <Footer />
    </main>
  )
}

export default App
